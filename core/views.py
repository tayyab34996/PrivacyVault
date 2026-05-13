import csv
import io
from datetime import timedelta
from django.conf import settings
from django.contrib import messages
from django.core.mail import send_mail
from django.contrib.auth import authenticate, get_user_model, login, logout
from django.contrib.auth.decorators import login_required, user_passes_test
from django.db import DatabaseError
from django.db.models import Avg, Count, Prefetch, Q
from django.http import HttpResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from django.contrib.sessions.models import Session
from django.utils import timezone
from django.utils.dateparse import parse_date

from .exposure_service import exposure_band, run_exposure_scan
from .forms import (
    BreachRecordForm,
    CompanyForm,
    ConsentRecordForm,
    DataCategoryForm,
    DeletionRequestForm,
    CSVImportForm,
    ExposureScanForm,
    ProfileUpdateForm,
    RatingForm,
    UserLoginForm,
    UserRegistrationForm,
)
from .models import (
    ActivityLog,
    BreachRecord,
    BreachMatch,
    Company,
    ConsentRecord,
    DataCategory,
    DeletionRequest,
    ExposureRecommendation,
    ExposureScan,
    Notification,
    Rating,
    UserCompany,
)


def log_activity(user, action, company=None, details=''):
    # We no longer manually log this because the SQL Triggers 
    # (e.g. trg_AuditUserChanges, trg_AuditDeletionRequests) handle it at the database level!
    pass


def create_notification(user, title, message, link=''):
    Notification.objects.create(user=user, title=title, message=message, link=link)


def sensitivity_weight(sensitivity):
    if sensitivity == 'high':
        return 3
    if sensitivity == 'medium':
        return 2
    return 1


def _home_exposure_context(user):
    ctx = {
        'exposure_db_ready': False,
        'exposure_score': None,
        'exposure_band_key': None,
        'exposure_band_label': None,
        'exposure_total_breach_matches': 0,
        'exposure_recent_scans': [],
        'exposure_high_risk_matches': [],
        'exposure_recommended_actions': [],
        'exposure_has_scans': False,
    }
    try:
        scans = ExposureScan.objects.filter(user=user).order_by('-scan_date')
        ctx['exposure_db_ready'] = True
        latest = scans.first()
        ctx['exposure_has_scans'] = latest is not None
        if latest:
            ctx['exposure_score'] = latest.risk_score
            bkey, blabel = exposure_band(latest.risk_score)
            ctx['exposure_band_key'] = bkey
            ctx['exposure_band_label'] = blabel
        ctx['exposure_total_breach_matches'] = BreachMatch.objects.filter(scan__user=user).count()
        ctx['exposure_recent_scans'] = list(scans[:5])
        ctx['exposure_high_risk_matches'] = list(
            BreachMatch.objects.filter(scan__user=user, breach__severity__iexact='high')
            .select_related('breach__company', 'scan')
            .order_by('-scan__scan_date', '-match_id')[:5]
        )
        if latest:
            recs = list(ExposureRecommendation.objects.filter(scan=latest))
            pri = {'high': 0, 'medium': 1, 'low': 2}
            recs.sort(key=lambda r: pri.get((r.priority_level or 'low').lower(), 3))
            ctx['exposure_recommended_actions'] = recs[:8]
    except DatabaseError:
        pass
    return ctx


def calculate_risk_score(user):
    from django.db import connection
    
    # Use vw_UserActiveConsents View to get sensitivity levels
    with connection.cursor() as cursor:
        cursor.execute("SELECT sensitivity_level FROM vw_UserActiveConsents WHERE user_id = %s", [user.user_id])
        rows = cursor.fetchall()
        
    data_weight = 0
    for row in rows:
        sensitivity = str(row[0] or 'low').lower()
        if sensitivity == 'high':
            data_weight += 3
        elif sensitivity == 'medium':
            data_weight += 2
        else:
            data_weight += 1

    # Use vw_CompanyRiskProfile View to get average rating of connected companies.
    # Unrated companies must count as neutral (3.0), not 0 — otherwise (5 - 0) * 10 skews risk.
    company_ids = list(UserCompany.objects.filter(user=user).values_list('company_id', flat=True))
    avg_rating = 3.0
    if company_ids:
        placeholders = ','.join(['%s'] * len(company_ids))
        with connection.cursor() as cursor:
            cursor.execute(f"SELECT average_rating FROM vw_CompanyRiskProfile WHERE company_id IN ({placeholders})", company_ids)
            rows = cursor.fetchall()
        per_company = []
        for row in rows:
            try:
                v = float(row[0])
            except (TypeError, ValueError):
                v = 3.0
            if v <= 0:
                v = 3.0
            per_company.append(v)
        if per_company:
            avg_rating = sum(per_company) / len(per_company)

    companies_count = len(company_ids)
    risk = (companies_count * 5) + (data_weight * 10) + ((5 - avg_rating) * 10)
    return min(100, int(round(risk)))


def landing_page(request):
    return render(request, 'landing.aspx')


@login_required
def home(request):
    today = timezone.now().date()
    
    # Raw SQL queries from Views for Dashboard Statistics
    from django.db import connection
    with connection.cursor() as cursor:
        cursor.execute("SELECT COUNT(DISTINCT consent_id) FROM vw_UserActiveConsents WHERE user_id = %s", [request.user.user_id])
        row = cursor.fetchone()
        active_consents_count = row[0] if row else 0
        
        cursor.execute("SELECT COUNT(*) FROM vw_PendingDeletionRequests WHERE user_id = %s", [request.user.user_id])
        row2 = cursor.fetchone()
        pending_requests_count = row2[0] if row2 else 0

    # Fallback ORM for simple queries
    consents = ConsentRecord.objects.filter(user=request.user)
    expired_consents = consents.filter(expiry_date__lt=today)
    upcoming_expirations = consents.filter(expiry_date__range=(today, today + timedelta(days=30)))
    
    context = {
        'companies_count': UserCompany.objects.filter(user=request.user).count(),
        'active_consents_count': active_consents_count,
        'expired_consents_count': expired_consents.count(),
        'pending_requests_count': pending_requests_count,
        'risk_score': calculate_risk_score(request.user),
        'recent_activities': ActivityLog.objects.filter(user=request.user)[:10],
        'upcoming_expirations': upcoming_expirations.order_by('expiry_date')[:5],
        'notifications': Notification.objects.filter(user=request.user, is_read=False)[:5],
    }
    context.update(_home_exposure_context(request.user))
    return render(request, 'dashboard.aspx', context)


@login_required
def exposure_scan_view(request):
    try:
        recent_scans = list(
            ExposureScan.objects.filter(user=request.user).order_by('-scan_date')[:12]
        )
    except DatabaseError:
        messages.error(
            request,
            'Exposure monitoring is not set up yet. Ask your administrator to (re)build the database from privacyvault_schema.sql so exposure tables exist.',
        )
        return render(
            request,
            'scan_exposure.aspx',
            {
                'form': ExposureScanForm(initial={'email': request.user.email}),
                'recent_scans': [],
                'viewing_scan': None,
                'breach_matches': [],
                'recommendations': [],
                'exposure_band': None,
                'db_ready': False,
            },
        )

    viewing_scan = None
    raw_scan_id = request.GET.get('scan_id')
    if raw_scan_id:
        try:
            viewing_scan = ExposureScan.objects.prefetch_related(
                Prefetch(
                    'breach_matches',
                    queryset=BreachMatch.objects.select_related('breach__company'),
                ),
                'recommendations',
            ).get(scan_id=int(raw_scan_id), user=request.user)
        except (ValueError, ExposureScan.DoesNotExist):
            viewing_scan = None

    if request.method == 'POST':
        form = ExposureScanForm(request.POST)
        if form.is_valid():
            try:
                scan = run_exposure_scan(
                    request.user,
                    form.cleaned_data['email'],
                    form.cleaned_data.get('phone') or '',
                    form.cleaned_data.get('usernames') or '',
                )
                messages.success(
                    request,
                    'Scan finished. Results reflect known breach records stored in PrivacyVault only — not live internet or dark-web monitoring.',
                )
                return redirect(f"{reverse('exposure_scan')}?scan_id={scan.scan_id}")
            except DatabaseError:
                messages.error(
                    request,
                    'Could not save this scan. Ensure the database schema includes exposure tables from privacyvault_schema.sql.',
                )
    else:
        form = ExposureScanForm(initial={'email': request.user.email})

    breach_matches = []
    recommendations = []
    exposure_band_info = None
    if viewing_scan:
        breach_matches = list(viewing_scan.breach_matches.all())
        recommendations = list(viewing_scan.recommendations.all())
        pri = {'high': 0, 'medium': 1, 'low': 2}
        recommendations.sort(
            key=lambda r: pri.get((r.priority_level or 'low').lower(), 3)
        )
        exposure_band_info = exposure_band(viewing_scan.risk_score)

    return render(
        request,
        'scan_exposure.aspx',
        {
            'form': form,
            'recent_scans': recent_scans,
            'viewing_scan': viewing_scan,
            'breach_matches': breach_matches,
            'recommendations': recommendations,
            'exposure_band': exposure_band_info,
            'db_ready': True,
        },
    )

def signup_view(request):
    if request.method == 'POST':
        form = UserRegistrationForm(request.POST)
        if form.is_valid():
            email = form.cleaned_data.get('email', '').lower()
            try:
                if form.existing_user:
                    user = form.existing_user
                    updated_fields = []
                    new_password = form.cleaned_data.get('password1')
                    if new_password:
                        user.set_password(new_password)
                        updated_fields.append('password')
                    if form.cleaned_data.get('name') and user.name != form.cleaned_data['name']:
                        user.name = form.cleaned_data['name']
                        updated_fields.append('name')
                    if user.phone_number != form.cleaned_data.get('phone_number', ''):
                        user.phone_number = form.cleaned_data.get('phone_number', '')
                        updated_fields.append('phone_number')
                    if user.account_status != 'active':
                        user.account_status = 'active'
                        updated_fields.append('account_status')
                    if updated_fields:
                        user.save(update_fields=updated_fields)
                else:
                    user_obj = form.save(commit=False)
                    user_obj.email = email
                    from django.db import connection
                    with connection.cursor() as cursor:
                        cursor.execute(
                            "EXEC sp_RegisterUser @name=%s, @email=%s, @password_hash=%s, @phone=%s",
                            [user_obj.name, user_obj.email, user_obj.password, user_obj.phone_number]
                        )
                    
                    user = get_user_model().objects.get(email__iexact=user_obj.email)
                    if user.account_status != 'active':
                        user.account_status = 'active'
                        user.save(update_fields=['account_status'])
                login(request, user)
                log_activity(user, 'Account created')
                messages.success(request, 'Registration successful. Welcome to PrivacyVault!')
                return redirect('home')
            except Exception as e:
                messages.error(request, f"A system error occurred. Please ensure the database is initialized properly.")
    else:
        form = UserRegistrationForm()
    return render(request, 'signup.aspx', {'form': form})

def login_view(request):
    if request.method == 'POST':
        form = UserLoginForm(request.POST)
        if form.is_valid():
            email = form.cleaned_data.get('email')
            password = form.cleaned_data.get('password')
            try:
                user = authenticate(request, email=email, password=password)
                if user is not None:
                    if not user.is_active:
                        user.account_status = 'active'
                        user.save(update_fields=['account_status'])
                    login(request, user)
                    log_activity(user, 'Logged in')
                    return redirect('home')
                else:
                    messages.error(request, 'Invalid email or password.')
            except Exception as e:
                messages.error(request, "Database connection failed. Please contact the administrator or check your database setup.")
    else:
        form = UserLoginForm()
    return render(request, 'login.aspx', {'form': form})

@login_required
def logout_view(request):
    log_activity(request.user, 'Logged out')
    logout(request)
    messages.info(request, 'You have been logged out.')
    return redirect('login')


@login_required
def profile_view(request):
    if request.method == 'POST':
        form = ProfileUpdateForm(request.POST, instance=request.user)
        if form.is_valid():
            form.save()
            log_activity(request.user, 'Profile updated')
            messages.success(request, 'Profile updated.')
            return redirect('profile')
    else:
        form = ProfileUpdateForm(instance=request.user)
    return render(request, 'profile.aspx', {'form': form})


@login_required
def profile_delete(request):
    if request.method == 'POST':
        user = request.user
        logout(request)
        user.delete()
        messages.info(request, 'Account deleted.')
        return redirect('login')
    return redirect('profile')


@login_required
def company_list(request):
    search_query = request.GET.get('q', '').strip()
    companies = Company.objects.filter(user_companies__user=request.user).distinct()
    if search_query:
        companies = companies.filter(
            Q(name__icontains=search_query)
            | Q(category__icontains=search_query)
            | Q(website__icontains=search_query)
        )

    companies = companies.annotate(
        avg_rating=Avg('ratings__rating'),
        breaches_count=Count('breaches', distinct=True),
    )

    add_form = CompanyForm()
    rating_form = RatingForm()
    context = {
        'companies': companies.order_by('name'),
        'add_form': add_form,
        'rating_form': rating_form,
        'search_query': search_query,
    }
    return render(request, 'companies.aspx', context)


@login_required
def company_create(request):
    if request.method == 'POST':
        company_name = request.POST.get('name', '').strip()
        website = request.POST.get('website', '').strip()
        category = request.POST.get('category', '').strip()
        
        if company_name:
            company = Company.objects.filter(name__iexact=company_name).first()
            if company:
                if website: company.website = website
                if category: company.category = category
                company.save()
            else:
                company = Company.objects.create(name=company_name, website=website, category=category)
            UserCompany.objects.get_or_create(user=request.user, company=company)
            log_activity(request.user, 'Company added', company=company)
            messages.success(request, 'Company saved.')
        else:
            messages.error(request, 'Company name is required.')
    return redirect('companies')



@login_required
def company_import(request):
    if request.method == 'POST':
        form = CSVImportForm(request.POST, request.FILES)
        if form.is_valid():
            csv_file = form.cleaned_data['csv_file']
            decoded = csv_file.read().decode('utf-8')
            reader = csv.DictReader(io.StringIO(decoded))
            for row in reader:
                name = row.get('name', '').strip()
                if not name:
                    continue
                company, _created = Company.objects.get_or_create(name=name)
                company.website = row.get('website', company.website)
                company.category = row.get('category', company.category)
                company.save()
                UserCompany.objects.get_or_create(user=request.user, company=company)
            log_activity(request.user, 'Companies imported')
            messages.success(request, 'Companies imported successfully.')
    return redirect('companies')


@login_required
def company_update(request, company_id):
    company = get_object_or_404(Company, pk=company_id, user_companies__user=request.user)
    if request.method == 'POST':
        form = CompanyForm(request.POST, instance=company)
        if form.is_valid():
            form.save()
            log_activity(request.user, 'Company updated', company=company)
            messages.success(request, 'Company updated.')
    return redirect('companies')


@login_required
def company_delete(request, company_id):
    company = get_object_or_404(Company, pk=company_id, user_companies__user=request.user)
    if request.method == 'POST':
        UserCompany.objects.filter(user=request.user, company=company).delete()
        if not UserCompany.objects.filter(company=company).exists():
            if not ConsentRecord.objects.filter(company=company).exists():
                if not Rating.objects.filter(company=company).exists():
                    if not BreachRecord.objects.filter(company=company).exists():
                        company.delete()
        log_activity(request.user, 'Company removed', company=company)
        messages.info(request, 'Company removed from your list.')
    return redirect('companies')


@login_required
def rating_upsert(request, company_id):
    company = get_object_or_404(Company, pk=company_id, user_companies__user=request.user)
    if request.method == 'POST':
        form = RatingForm(request.POST)
        if form.is_valid():
            Rating.objects.update_or_create(
                user=request.user,
                company=company,
                defaults=form.cleaned_data,
            )
            log_activity(request.user, 'Company rated', company=company)
            messages.success(request, 'Rating saved.')
    return redirect('companies')


@login_required
def consent_list(request):
    today = timezone.now().date()
    consents = ConsentRecord.objects.filter(user=request.user).select_related('company').prefetch_related('data_categories')

    category_filter = request.GET.get('category')
    expiry_filter = request.GET.get('expiry')
    rating_filter = request.GET.get('rating')
    breach_filter = request.GET.get('breach')

    if category_filter:
        consents = consents.filter(data_categories__id=category_filter)
    if expiry_filter == 'upcoming':
        consents = consents.filter(expiry_date__range=(today, today + timedelta(days=30)))
    if expiry_filter == 'expired':
        consents = consents.filter(expiry_date__lt=today)
    if rating_filter:
        consents = consents.filter(company__ratings__rating__gte=rating_filter)
    if breach_filter == 'yes':
        consents = consents.filter(company__breaches__isnull=False)

    active_consents = consents.filter(Q(expiry_date__isnull=True) | Q(expiry_date__gte=today))
    expired_consents = consents.filter(expiry_date__lt=today)

    form = ConsentRecordForm()
    companies_for_user = Company.objects.filter(user_companies__user=request.user)
    form.fields['company'].queryset = companies_for_user

    active_ids = active_consents.values_list('consent_id', flat=True).distinct()
    display_consents = (
        ConsentRecord.objects.filter(consent_id__in=active_ids)
        .select_related('company')
        .prefetch_related('data_categories')
        .order_by('company__name', 'consent_id')
    )
    consent_rows = []
    for consent in display_consents:
        edit_form = ConsentRecordForm(instance=consent)
        edit_form.fields['company'].queryset = companies_for_user
        consent_rows.append({'consent': consent, 'edit_form': edit_form})

    context = {
        'consent_rows': consent_rows,
        'expired_consents': expired_consents.distinct(),
        'consent_form': form,
        'import_form': CSVImportForm(),
        'categories': DataCategory.objects.all(),
        'companies_for_user': companies_for_user,
        'filters': {
            'category': category_filter,
            'expiry': expiry_filter,
            'rating': rating_filter,
            'breach': breach_filter,
        },
    }
    return render(request, 'consents.aspx', context)


@login_required
def consent_create(request):
    if request.method == 'POST':
        form = ConsentRecordForm(request.POST)
        form.fields['company'].queryset = Company.objects.filter(user_companies__user=request.user)
        if form.is_valid():
            company = form.cleaned_data['company']
            expiry_date = form.cleaned_data['expiry_date']
            categories = form.cleaned_data['data_categories']
            if not categories:
                messages.error(request, 'Select at least one data category.')
                return redirect('consents')
            try:
                from django.db import connection
                with connection.cursor() as cursor:
                    for category in categories:
                        cursor.execute(
                            "EXEC sp_GrantConsent @user_id=%s, @company_id=%s, @consent_expiry_date=%s, @category_id=%s, @notes=%s",
                            [request.user.user_id, company.company_id, expiry_date, category.category_id, ''],
                        )
                UserCompany.objects.get_or_create(user=request.user, company=company)
                log_activity(request.user, 'Consent recorded', company=company)
                messages.success(request, 'Consent recorded.')
            except Exception:
                messages.error(
                    request,
                    'Could not record consent. Ensure SQL Server has sp_GrantConsent and your database is reachable.',
                )
        else:
            messages.error(request, 'Fix the errors below and try again.')
            for err in form.errors.values():
                for msg in err:
                    messages.error(request, msg)
    return redirect('consents')


@login_required
def consent_import(request):
    if request.method == 'POST':
        form = CSVImportForm(request.POST, request.FILES)
        if form.is_valid():
            try:
                csv_file = form.cleaned_data['csv_file']
                decoded = csv_file.read().decode('utf-8')
                reader = csv.DictReader(io.StringIO(decoded))
                imported = 0
                for row in reader:
                    company_name = (row.get('company') or '').strip()
                    if not company_name:
                        continue
                    company, _created = Company.objects.get_or_create(name=company_name)
                    UserCompany.objects.get_or_create(user=request.user, company=company)
                    expiry_raw = (row.get('expiry_date') or '').strip()
                    expiry_date = parse_date(expiry_raw) if expiry_raw else None
                    consent, _created = ConsentRecord.objects.update_or_create(
                        user=request.user,
                        company=company,
                        defaults={'expiry_date': expiry_date},
                    )
                    categories = []
                    for cat_name in (row.get('data_categories') or '').split(','):
                        clean_name = cat_name.strip()
                        if not clean_name:
                            continue
                        category, _created = DataCategory.objects.get_or_create(
                            category_name=clean_name,
                            defaults={'sensitivity': 'low', 'description': ''},
                        )
                        categories.append(category)
                    if categories:
                        consent.data_categories.set(categories)
                        imported += 1
                log_activity(request.user, 'Consents imported')
                if imported:
                    messages.success(request, f'Imported or updated {imported} consent row(s).')
                else:
                    messages.warning(
                        request,
                        'No rows imported. CSV needs columns: company, expiry_date (optional, YYYY-MM-DD), '
                        'data_categories (comma-separated names matching your data categories).',
                    )
            except Exception:
                messages.error(request, 'CSV import failed. Check file encoding (UTF-8) and column names.')
        else:
            messages.error(request, 'Choose a CSV file to upload.')
    return redirect('consents')


@login_required
def consent_update(request, consent_id):
    consent = get_object_or_404(ConsentRecord, pk=consent_id, user=request.user)
    if request.method == 'POST':
        form = ConsentRecordForm(request.POST, instance=consent)
        form.fields['company'].queryset = Company.objects.filter(user_companies__user=request.user)
        if form.is_valid():
            form.save()
            log_activity(request.user, 'Consent updated', company=consent.company)
            messages.success(request, 'Consent updated.')
    return redirect('consents')


@login_required
def consent_delete(request, consent_id):
    consent = get_object_or_404(ConsentRecord, pk=consent_id, user=request.user)
    if request.method == 'POST':
        company = consent.company
        consent.delete()
        log_activity(request.user, 'Consent deleted', company=company)
        messages.info(request, 'Consent deleted.')
    return redirect('consents')


@login_required
def deletion_request_list(request):
    requests = DeletionRequest.objects.filter(user=request.user).select_related('company')
    form = DeletionRequestForm()
    form.fields['company'].queryset = Company.objects.filter(user_companies__user=request.user)
    return render(
        request,
        'requests.aspx',
        {
            'requests': requests,
            'request_form': form,
            'status_choices': DeletionRequest.STATUS_CHOICES,
        },
    )


@login_required
def deletion_request_create(request):
    if request.method == 'POST':
        form = DeletionRequestForm(request.POST)
        form.fields['company'].queryset = Company.objects.filter(user_companies__user=request.user)
        if form.is_valid():
            deletion_request = form.save(commit=False)
            deletion_request.user = request.user
            deletion_request.save()
            log_activity(request.user, 'Deletion request created', company=deletion_request.company)
            messages.success(request, 'Deletion request created.')
    return redirect('requests')


@login_required
def deletion_request_update(request, request_id):
    deletion_request = get_object_or_404(DeletionRequest, pk=request_id, user=request.user)
    if request.method == 'POST':
        form = DeletionRequestForm(request.POST, instance=deletion_request)
        form.fields['company'].queryset = Company.objects.filter(user_companies__user=request.user)
        if form.is_valid():
            new_status = form.cleaned_data['status']
            if new_status == 'completed' and not request.user.is_staff:
                messages.error(request, 'Only administrators can mark requests as Completed.')
                return redirect('requests')
            
            # Save non-status fields (like target_data)
            form.save()

            # Execute Stored Procedure for the status update and cascading logic
            from django.db import connection
            with connection.cursor() as cursor:
                cursor.execute(
                    "EXEC sp_ProcessDeletionRequest @request_id=%s, @new_status=%s, @notes=%s",
                    [deletion_request.request_id, new_status, form.cleaned_data.get('note', '')]
                )
            log_activity(request.user, 'Deletion request updated', company=deletion_request.company)
            messages.success(request, 'Deletion request updated.')
    return redirect('requests')


@login_required
def deletion_request_delete(request, request_id):
    deletion_request = get_object_or_404(DeletionRequest, pk=request_id, user=request.user)
    if request.method == 'POST':
        company = deletion_request.company
        deletion_request.delete()
        log_activity(request.user, 'Deletion request deleted', company=company)
        messages.info(request, 'Deletion request deleted.')
    return redirect('requests')


@login_required
def export_report(request):
    export_format = request.GET.get('format', 'csv')
    if export_format == 'pdf':
        try:
            from reportlab.lib.pagesizes import letter
            from reportlab.pdfgen import canvas
        except ImportError:
            return HttpResponse('Install reportlab to export PDF reports.', status=500)

        response = HttpResponse(content_type='application/pdf')
        response['Content-Disposition'] = 'attachment; filename="privacyvault_report.pdf"'
        pdf = canvas.Canvas(response, pagesize=letter)
        y = 750
        pdf.setFont("Helvetica-Bold", 14)
        pdf.drawString(40, y, "PrivacyVault Report")
        y -= 30
        pdf.setFont("Helvetica", 10)
        pdf.drawString(40, y, f"User: {request.user.email}")
        y -= 20
        pdf.drawString(40, y, f"Companies: {UserCompany.objects.filter(user=request.user).count()}")
        y -= 20
        pdf.drawString(40, y, f"Consents: {ConsentRecord.objects.filter(user=request.user).count()}")
        y -= 20
        pdf.drawString(40, y, f"Deletion Requests: {DeletionRequest.objects.filter(user=request.user).count()}")
        y -= 30
        pdf.drawString(40, y, "Companies List:")
        y -= 20
        for company in Company.objects.filter(user_companies__user=request.user).order_by('name'):
            if y < 80:
                pdf.showPage()
                y = 750
            pdf.drawString(50, y, f"- {company.name} ({company.category or 'Uncategorized'})")
            y -= 14
        pdf.showPage()
        pdf.save()
        return response

    response = HttpResponse(content_type='text/csv')
    response['Content-Disposition'] = 'attachment; filename="privacyvault_report.csv"'
    writer = csv.writer(response)
    writer.writerow(['PrivacyVault Report', request.user.email])
    writer.writerow([])
    writer.writerow(['Company', 'Category', 'Website'])
    for company in Company.objects.filter(user_companies__user=request.user).order_by('name'):
        writer.writerow([company.name, company.category, company.website])
    writer.writerow([])
    writer.writerow(['Company', 'Data Categories', 'Expiry Date'])
    for consent in ConsentRecord.objects.filter(user=request.user).select_related('company').prefetch_related('data_categories'):
        categories = ', '.join([c.category_name for c in consent.data_categories.all()])
        writer.writerow([consent.company.name, categories, consent.expiry_date or ''])
    writer.writerow([])
    writer.writerow(['Company', 'Status', 'Target Data', 'Response Date'])
    for req in DeletionRequest.objects.filter(user=request.user).select_related('company'):
        writer.writerow([req.company.name, req.status, req.target_data, req.response_date or ''])
    return response


def is_staff_user(user):
    return user.is_staff


@login_required
@user_passes_test(is_staff_user)
def admin_panel(request):
    return render(
        request,
        'admin_panel.aspx',
        {
            'categories': DataCategory.objects.all(),
            'breaches': BreachRecord.objects.select_related('company').order_by('-breach_date'),
            'category_form': DataCategoryForm(),
            'breach_form': BreachRecordForm(),
        },
    )


@login_required
@user_passes_test(is_staff_user)
def data_category_create(request):
    if request.method == 'POST':
        form = DataCategoryForm(request.POST)
        if form.is_valid():
            form.save()
            log_activity(request.user, 'Data category created')
            messages.success(request, 'Data category created.')
    return redirect('admin_panel')


@login_required
@user_passes_test(is_staff_user)
def data_category_update(request, category_id):
    category = get_object_or_404(DataCategory, pk=category_id)
    if request.method == 'POST':
        form = DataCategoryForm(request.POST, instance=category)
        if form.is_valid():
            form.save()
            log_activity(request.user, 'Data category updated')
            messages.success(request, 'Data category updated.')
    return redirect('admin_panel')


@login_required
@user_passes_test(is_staff_user)
def data_category_delete(request, category_id):
    category = get_object_or_404(DataCategory, pk=category_id)
    if request.method == 'POST':
        category.delete()
        log_activity(request.user, 'Data category deleted')
        messages.info(request, 'Data category deleted.')
    return redirect('admin_panel')


@login_required
@user_passes_test(is_staff_user)
def breach_create(request):
    if request.method == 'POST':
        form = BreachRecordForm(request.POST)
        if form.is_valid():
            breach = form.save()
            affected_users = UserCompany.objects.filter(company=breach.company).values_list('user', flat=True)
            for user_id in set(affected_users):
                user = get_user_model().objects.get(pk=user_id)
                create_notification(
                    user,
                    'Breach Alert',
                    f"{breach.company.name} reported a {breach.severity} severity breach.",
                    link='/breaches/',
                )
                send_mail(
                    'PrivacyVault Breach Alert',
                    f"{breach.company.name} reported a {breach.severity} severity breach.",
                    settings.DEFAULT_FROM_EMAIL,
                    [user.email],
                    fail_silently=True,
                )
            log_activity(request.user, 'Breach recorded', company=breach.company)
            messages.success(request, 'Breach recorded.')
    return redirect('admin_panel')


@login_required
@user_passes_test(is_staff_user)
def breach_update(request, breach_id):
    breach = get_object_or_404(BreachRecord, pk=breach_id)
    if request.method == 'POST':
        form = BreachRecordForm(request.POST, instance=breach)
        if form.is_valid():
            form.save()
            log_activity(request.user, 'Breach updated', company=breach.company)
            messages.success(request, 'Breach updated.')
    return redirect('admin_panel')


@login_required
@user_passes_test(is_staff_user)
def breach_delete(request, breach_id):
    breach = get_object_or_404(BreachRecord, pk=breach_id)
    if request.method == 'POST':
        company = breach.company
        breach.delete()
        log_activity(request.user, 'Breach deleted', company=company)
        messages.info(request, 'Breach deleted.')
    return redirect('admin_panel')


@login_required
def breach_history(request):
    breaches = BreachRecord.objects.select_related('company').order_by('-breach_date')
    if not request.user.is_staff:
        breaches = breaches.filter(company__user_companies__user=request.user)

    severity = request.GET.get('severity')
    company_id = request.GET.get('company')
    if severity:
        breaches = breaches.filter(severity=severity)
    if company_id:
        breaches = breaches.filter(company_id=company_id)

    return render(
        request,
        'breach_history.aspx',
        {
            'breaches': breaches,
            'companies': Company.objects.filter(user_companies__user=request.user),
            'filters': {'severity': severity, 'company': company_id},
        },
    )


@login_required
def notifications_list(request):
    notifications = Notification.objects.filter(user=request.user)
    return render(request, 'notifications.aspx', {'notifications': notifications})


@login_required
def notification_mark_read(request, notification_id):
    if request.method == 'POST':
        notification = get_object_or_404(Notification, pk=notification_id, user=request.user)
        notification.is_read = True
        notification.save(update_fields=['is_read'])
    return redirect('notifications')


@login_required
def activity_log_view(request):
    logs = ActivityLog.objects.select_related('user')
    scope = request.GET.get('scope')
    if scope != 'all' or not request.user.is_staff:
        logs = logs.filter(user=request.user)

    action = request.GET.get('action')
    start_date = request.GET.get('start_date')
    end_date = request.GET.get('end_date')

    if action:
        logs = logs.filter(action_type__icontains=action)
    if start_date:
        logs = logs.filter(created_at__date__gte=start_date)
    if end_date:
        logs = logs.filter(created_at__date__lte=end_date)

    return render(
        request,
        'activity_log.aspx',
        {
            'logs': logs.order_by('-created_at')[:200],
            'filters': {
                'scope': scope,
                'action': action,
                'start_date': start_date,
                'end_date': end_date,
            },
        },
    )


@login_required
def session_list(request):
    sessions = []
    for session in Session.objects.all():
        data = session.get_decoded()
        if data.get('_auth_user_id') == str(request.user.pk):
            sessions.append({
                'session_key': session.session_key,
                'expire_date': session.expire_date,
                'is_current': session.session_key == request.session.session_key,
            })
    return render(request, 'sessions.aspx', {'sessions': sessions})


@login_required
def logout_other_sessions(request):
    if request.method == 'POST':
        for session in Session.objects.all():
            data = session.get_decoded()
            if data.get('_auth_user_id') == str(request.user.pk):
                if session.session_key != request.session.session_key:
                    session.delete()
        messages.info(request, 'Logged out of other sessions.')
    return redirect('sessions')


@login_required
def session_terminate(request, session_key):
    if request.method == 'POST':
        session = get_object_or_404(Session, session_key=session_key)
        data = session.get_decoded()
        if data.get('_auth_user_id') == str(request.user.pk):
            session.delete()
            messages.info(request, 'Session terminated.')
    return redirect('sessions')
