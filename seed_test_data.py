import os
import django
from django.utils import timezone
import random
from datetime import timedelta

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "PrivacyVault.settings")
django.setup()

from core.models import CustomUser, Company, DataCategory, BreachRecord, ConsentRecord, ConsentData, Rating, ActivityLog, ExposureScan, BreachMatch

def seed():
    print("Starting data seed...")

    # 1. Create Companies
    companies_data = [
        {"name": "TechGlobal", "website": "https://techglobal.com", "category": "Technology", "country": "USA", "is_verified": True},
        {"name": "HealthPlus", "website": "https://healthplus.org", "category": "Healthcare", "country": "Canada", "is_verified": True},
        {"name": "ShopMart", "website": "https://shopmart.com", "category": "Retail", "country": "UK", "is_verified": False},
        {"name": "FinBank", "website": "https://finbank.com", "category": "Finance", "country": "USA", "is_verified": True},
        {"name": "SocialConnect", "website": "https://socialconnect.com", "category": "Social Media", "country": "USA", "is_verified": True},
    ]

    companies = []
    for cd in companies_data:
        company, created = Company.objects.get_or_create(name=cd["name"], defaults=cd)
        companies.append(company)
        if created:
            print(f"Created Company: {company.name}")

    # 2. Create Data Categories
    categories_data = [
        {"name": "Personal Identification", "sensitivity": "high", "description": "Names, SSN, DOB, etc."},
        {"name": "Financial Data", "sensitivity": "high", "description": "Credit cards, bank accounts, income"},
        {"name": "Health Information", "sensitivity": "high", "description": "Medical records, prescriptions"},
        {"name": "Contact Information", "sensitivity": "medium", "description": "Email, phone number, address"},
        {"name": "Usage Data", "sensitivity": "low", "description": "App usage, browsing history"},
        {"name": "Device Information", "sensitivity": "low", "description": "IP address, device ID"},
    ]

    categories = []
    for cd in categories_data:
        cat, created = DataCategory.objects.get_or_create(category_name=cd["name"], defaults={"sensitivity": cd["sensitivity"], "description": cd["description"]})
        categories.append(cat)
        if created:
            print(f"Created Data Category: {cat.category_name}")

    # 3. Create Breach Records
    breaches_data = [
        {"company_idx": 0, "type": "Hacking", "severity": "high", "desc": "Servers compromised in a ransomware attack exposing sensitive user data.", "date_offset": 30},
        {"company_idx": 2, "type": "Data Leak", "severity": "medium", "desc": "Unsecured database exposed customer transaction records.", "date_offset": 120},
        {"company_idx": 4, "type": "Phishing", "severity": "high", "desc": "Employees tricked into revealing admin credentials, leading to data exfiltration.", "date_offset": 10},
    ]

    breach_records = []
    for bd in breaches_data:
        company = companies[bd["company_idx"]]
        breach_date = timezone.now().date() - timedelta(days=bd["date_offset"])
        breach, created = BreachRecord.objects.get_or_create(
            company=company, 
            breach_date=breach_date,
            defaults={"breach_type": bd["type"], "severity": bd["severity"], "description": bd["desc"]}
        )
        breach_records.append(breach)
        if created:
            print(f"Created Breach Record for: {company.name}")

    # 4. Attach data to existing users
    users = CustomUser.objects.all()
    if not users:
        print("No users found. Please create a user first.")
        return

    for user in users:
        print(f"Processing data for user: {user.email}")
        
        # Consents
        # User gives consent to 2-3 random companies
        user_companies = random.sample(companies, random.randint(2, 4))
        for comp in user_companies:
            consent, created = ConsentRecord.objects.get_or_create(
                user=user,
                company=comp,
                defaults={
                    "consent_given_date": timezone.now().date() - timedelta(days=random.randint(1, 100)),
                    "consent_status": "active",
                    "notes": "Standard terms agreed."
                }
            )
            if created:
                # Add categories to consent
                consent_cats = random.sample(categories, random.randint(1, 3))
                for cat in consent_cats:
                    ConsentData.objects.get_or_create(consent=consent, category=cat)
        
        # Exposure Scans
        scan_date = timezone.now() - timedelta(days=random.randint(0, 5))
        scan, scan_created = ExposureScan.objects.get_or_create(
            user=user,
            email_checked=user.email,
            defaults={
                "scan_date": scan_date,
                "risk_score": random.randint(10, 80),
                "scan_status": "completed"
            }
        )
        if scan_created and random.choice([True, False]): # 50% chance of having a breach match
            breach = random.choice(breach_records)
            BreachMatch.objects.get_or_create(
                scan=scan,
                breach=breach,
                defaults={
                    "data_exposed": "Email, Passwords",
                    "description": "Your email was found in this database leak."
                }
            )
            
        # Activity Logs
        # ActivityLog.objects.get_or_create(user=user, action_type="LOGIN", description="User logged in successfully", defaults={"created_at": timezone.now() - timedelta(hours=2)})
        # ActivityLog.objects.get_or_create(user=user, action_type="CONSENT_UPDATE", description="User updated consent settings", defaults={"created_at": timezone.now() - timedelta(days=1)})

    print("Data seed complete! You can now log in and see your dashboard populated with data.")

if __name__ == "__main__":
    seed()
