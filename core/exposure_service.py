"""
Known exposure monitoring: correlates user-supplied identifiers with on-file breach_records.
Does not perform live dark-web or illegal-activity detection.
"""
from urllib.parse import urlparse

from django.db import transaction
from django.utils import timezone

from .models import BreachRecord, ConsentRecord, ExposureRecommendation, ExposureScan, BreachMatch, UserCompany

SEVERITY_POINTS = {'high': 40, 'medium': 20, 'low': 10}

COMMON_EMAIL_DOMAINS = {
    'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com', 'icloud.com',
    'live.com', 'msn.com', 'proton.me', 'protonmail.com', 'aol.com',
}


def _infer_data_exposed(breach):
    parts = ['email addresses']
    text = ' '.join(filter(None, [breach.description or '', breach.breach_type or ''])).lower()
    if 'password' in text or 'credential' in text:
        parts.append('passwords or credentials')
    if 'phone' in text:
        parts.append('phone numbers')
    if 'payment' in text or 'card' in text or 'financial' in text:
        parts.append('payment or financial data')
    if 'address' in text:
        parts.append('physical addresses')
    return ', '.join(dict.fromkeys(parts))


def _email_domain(email):
    email = (email or '').strip().lower()
    if '@' not in email:
        return '', ''
    local, _, domain = email.partition('@')
    return local.strip(), domain.strip()


def _website_host(website):
    if not website:
        return ''
    w = website.strip().lower()
    if not w.startswith(('http://', 'https://')):
        w = 'https://' + w
    host = (urlparse(w).hostname or '').lower()
    if host.startswith('www.'):
        host = host[4:]
    return host


def _host_matches_email_domain(host, email_domain):
    if not host or not email_domain:
        return False
    ed = email_domain.lower().strip()
    if host == ed:
        return True
    if host.endswith('.' + ed) or ed.endswith('.' + host):
        return True
    return False


def find_matching_breaches(user, email, phone, usernames_raw):
    """
    Simulated / known-source matching only:
    - breaches for companies the user already linked in PrivacyVault
    - breaches where the company website host matches the email domain (work / vendor email)
    - breaches where a submitted username strongly overlaps the company name
    """
    email = (email or '').strip().lower()
    local_part, email_domain = _email_domain(email)
    usernames = [u.strip().lower() for u in (usernames_raw or '').split(',') if u.strip()]
    phone_digits = ''.join(c for c in (phone or '') if c.isdigit())

    user_company_ids = set(
        UserCompany.objects.filter(user=user).values_list('company_id', flat=True)
    )
    user_company_ids.update(
        ConsentRecord.objects.filter(user=user).values_list('company_id', flat=True)
    )

    matched = []
    seen = set()

    for breach in BreachRecord.objects.select_related('company').all():
        if breach.breach_id in seen:
            continue
        company = breach.company
        cname = (company.name or '').lower()
        matched_reason = None

        if company.company_id in user_company_ids:
            matched_reason = (
                'This company appears in your PrivacyVault profile (linked company or consent), '
                'and a breach is on record in our database.'
            )
        elif email_domain and email_domain not in COMMON_EMAIL_DOMAINS:
            host = _website_host(company.website or '')
            if _host_matches_email_domain(host, email_domain):
                matched_reason = (
                    'Your email domain matches this organization’s website domain; '
                    'a known breach record exists in our database (simulated correlation).'
                )
            elif cname.replace(' ', '') in email_domain.replace('.', '').replace('-', ''):
                matched_reason = (
                    'Company name appears related to your email domain; '
                    'breach correlation is based on stored breach records only.'
                )

        if not matched_reason and usernames:
            for un in usernames:
                if len(un) < 3:
                    continue
                if un in cname or cname in un:
                    matched_reason = (
                        'Submitted username overlaps a breached vendor name in our database '
                        '(illustrative match for coursework — not a live identity search).'
                    )
                    break

        if not matched_reason and phone_digits and len(phone_digits) >= 7:
            blob = f'{breach.description or ""} {breach.breach_type or ""}'.lower()
            if 'phone' in blob or 'sms' in blob:
                matched_reason = 'Breach description references phone-related data; optional phone correlation.'

        if matched_reason:
            seen.add(breach.breach_id)
            matched.append((breach, matched_reason))

    return matched


def compute_exposure_risk_score(matches_with_reasons):
    total = 0
    for breach, _reason in matches_with_reasons:
        sev = (breach.severity or 'low').lower()
        pts = SEVERITY_POINTS.get(sev, 10)
        de = _infer_data_exposed(breach)
        types_count = max(1, de.count(',') + 1)
        bonus = min(25, types_count * 5)
        total += pts + bonus
    return min(100, total)


def exposure_band(score):
    if score <= 30:
        return 'low', 'Low (known sources)'
    if score <= 70:
        return 'medium', 'Medium (known sources)'
    return 'high', 'High (known sources)'


def build_recommendations(user, matches_with_reasons, risk_score, expired_consent_count):
    recs = []
    seen = set()

    def add(title, desc, priority):
        key = title.lower()
        if key in seen:
            return
        seen.add(key)
        recs.append((title, desc, priority))

    if risk_score >= 71:
        add(
            'Change passwords for affected accounts',
            'Exposure score from known breach records is high. Use unique, strong passwords for each service.',
            'high',
        )
    elif risk_score >= 31:
        add(
            'Rotate passwords where relevant',
            'Medium exposure from correlated breach records. Update passwords especially if reused across sites.',
            'medium',
        )

    if matches_with_reasons:
        add(
            'Enable two-factor authentication (2FA)',
            'Turn on 2FA on important accounts to reduce takeover risk if credentials appeared in past incidents.',
            'medium',
        )
        add(
            'Remove or secure inactive accounts',
            'Delete old accounts you no longer need, especially if passwords were reused.',
            'medium',
        )

    for breach, _ in matches_with_reasons[:5]:
        add(
            f'Contact or review notices from {breach.company.name}',
            f'A breach dated {breach.breach_date} is on file. Check the company’s official security communications and reset credentials if you use the service.',
            'high' if (breach.severity or '').lower() == 'high' else 'medium',
        )

    if expired_consent_count:
        add(
            'Revoke or renew expired consents',
            f'You have {expired_consent_count} expired consent record(s). Review them in Consents and revoke data you no longer want shared.',
            'medium',
        )

    if not recs:
        add(
            'No on-file breach correlation this run',
            'Our stored breach database did not match your inputs this time. Re-run after adding companies or when new breach records are published.',
            'low',
        )

    return recs


@transaction.atomic
def run_exposure_scan(user, email_checked, phone_checked, usernames_checked):
    today = timezone.now().date()
    expired_consent_count = (
        ConsentRecord.objects.filter(user=user, expiry_date__lt=today)
        .exclude(consent_status__iexact='revoked')
        .count()
    )

    matches = find_matching_breaches(user, email_checked, phone_checked, usernames_checked)
    risk = compute_exposure_risk_score(matches)

    scan = ExposureScan.objects.create(
        user=user,
        email_checked=email_checked.strip()[:255],
        phone_checked=(phone_checked or '').strip()[:30] or None,
        usernames_checked=(usernames_checked or '').strip()[:500] or None,
        scan_date=timezone.now(),
        risk_score=risk,
        scan_status='completed',
    )

    for breach, reason in matches:
        data_exposed = _infer_data_exposed(breach)
        base_desc = (breach.description or 'Breach on record in PrivacyVault.').strip()
        BreachMatch.objects.create(
            scan=scan,
            breach=breach,
            data_exposed=data_exposed[:500],
            description=f'{base_desc} — {reason}'[:1000],
        )

    for title, description, priority in build_recommendations(
        user, matches, risk, expired_consent_count
    ):
        ExposureRecommendation.objects.create(
            scan=scan,
            title=title[:200],
            description=description[:1000],
            priority_level=priority,
        )

    return scan
