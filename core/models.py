from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.conf import settings
from django.db import models
from django.utils import timezone

class CustomUserManager(BaseUserManager):
    def create_user(self, email, name, password=None, **extra_fields):
        if not email:
            raise ValueError('The Email field must be set')
        email = self.normalize_email(email)
        user = self.model(email=email, name=name, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, name, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        return self.create_user(email, name, password, **extra_fields)

class CustomUser(AbstractBaseUser):
    user_id = models.AutoField(primary_key=True)
    email = models.EmailField(unique=True)
    name = models.CharField(max_length=150)
    phone_number = models.CharField(max_length=20, blank=True, db_column='phone')
    account_status = models.CharField(max_length=20, default='active')
    
    # Map required Django AbstractBaseUser fields
    password = models.CharField(max_length=128, db_column='password_hash')
    last_login = models.DateTimeField(blank=True, null=True, db_column='last_login')
    
    date_joined = models.DateTimeField(default=timezone.now, db_column='created_at')
    updated_at = models.DateTimeField(blank=True, null=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['name']

    objects = CustomUserManager()

    class Meta:
        db_table = 'users'
        managed = False

    @property
    def is_active(self):
        return (self.account_status or '').strip().lower() == 'active'

    @property
    def is_staff(self):
        admin_emails = {email.lower() for email in getattr(settings, 'ADMIN_EMAILS', [])}
        return (self.email or '').lower() in admin_emails

    @property
    def is_superuser(self):
        return self.is_staff

    def has_perm(self, perm, obj=None):
        return self.is_superuser

    def has_module_perms(self, app_label):
        return self.is_superuser

    def __str__(self):
        return self.email

    def get_full_name(self):
        return self.name

    def get_short_name(self):
        return self.name.split()[0]

class Company(models.Model):
    company_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=255, unique=True)
    website = models.URLField(blank=True, null=True)
    category = models.CharField(max_length=100, blank=True)
    country = models.CharField(max_length=100, blank=True)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        db_table = 'companies'
        managed = False

    def __str__(self):
        return self.name


class UserCompany(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='user_companies')
    company = models.ForeignKey(Company, on_delete=models.CASCADE, related_name='user_companies')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'company')

    def __str__(self):
        return f"{self.user.email} - {self.company.name}"

class DataCategory(models.Model):
    category_id = models.AutoField(primary_key=True)
    SENSITIVITY_CHOICES = (
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
    )
    category_name = models.CharField(max_length=100, unique=True)
    sensitivity = models.CharField(max_length=10, choices=SENSITIVITY_CHOICES, default='low', db_column='sensitivity_level')
    description = models.CharField(max_length=255, blank=True)
    
    class Meta:
        db_table = 'data_categories'
        managed = False

    def __str__(self):
        return self.category_name

class ConsentRecord(models.Model):
    consent_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='consents')
    company = models.ForeignKey(Company, on_delete=models.CASCADE, related_name='consents')
    data_categories = models.ManyToManyField(DataCategory, through='ConsentData', related_name='consents')
    consent_given_date = models.DateField(default=timezone.now)
    expiry_date = models.DateField(blank=True, null=True, db_column='consent_expiry_date')
    consent_status = models.CharField(max_length=20, default='active')
    notes = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'consents'
        managed = False
        unique_together = ('user', 'company')
        
    def is_expired(self):
        if self.expiry_date:
            return self.expiry_date < timezone.now().date()
        return False

class DeletionRequest(models.Model):
    request_id = models.AutoField(primary_key=True)
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('completed', 'Completed'),
        ('rejected', 'Rejected'),
    )
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='deletion_requests')
    company = models.ForeignKey(Company, on_delete=models.CASCADE)
    request_date = models.DateField(default=timezone.now)
    target_data = models.CharField(max_length=255, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    response_date = models.DateField(blank=True, null=True)
    note = models.TextField(blank=True, db_column='notes')

    class Meta:
        db_table = 'deletion_requests'
        managed = False

class Rating(models.Model):
    rating_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='ratings')
    company = models.ForeignKey(Company, on_delete=models.CASCADE, related_name='ratings')
    rating = models.IntegerField(choices=[(i, i) for i in range(1, 6)])
    review = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ratings'
        managed = False
        unique_together = ('user', 'company')

class BreachRecord(models.Model):
    breach_id = models.AutoField(primary_key=True)
    SEVERITY_CHOICES = (
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
    )
    company = models.ForeignKey(Company, on_delete=models.CASCADE, related_name='breaches')
    breach_date = models.DateField()
    breach_type = models.CharField(max_length=100, blank=True)
    severity = models.CharField(max_length=10, choices=SEVERITY_CHOICES, default='medium')
    description = models.TextField(db_column='description')

    class Meta:
        db_table = 'breach_records'
        managed = False


class ConsentData(models.Model):
    consent_data_id = models.AutoField(primary_key=True)
    consent = models.ForeignKey(ConsentRecord, on_delete=models.CASCADE, db_column='consent_id')
    category = models.ForeignKey(DataCategory, on_delete=models.CASCADE, db_column='category_id')

    class Meta:
        db_table = 'consent_data'
        managed = False
        unique_together = ('consent', 'category')

class ActivityLog(models.Model):
    log_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='activities')
    action_type = models.CharField(max_length=50)
    table_name = models.CharField(max_length=100, blank=True)
    description = models.CharField(max_length=255, blank=True, db_column='description')
    created_at = models.DateTimeField(default=timezone.now, db_column='created_at')

    class Meta:
        db_table = 'activity_logs'
        managed = False
        ordering = ['-created_at']


class Notification(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=200)
    message = models.TextField()
    link = models.CharField(max_length=255, blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']


class ExposureScan(models.Model):
    """User-initiated known exposure check (correlates with on-file breach_records only)."""

    scan_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(
        CustomUser, on_delete=models.CASCADE, related_name='exposure_scans'
    )
    email_checked = models.CharField(max_length=255)
    phone_checked = models.CharField(max_length=30, blank=True, null=True)
    usernames_checked = models.CharField(max_length=500, blank=True, null=True)
    scan_date = models.DateTimeField()
    risk_score = models.IntegerField(default=0)
    scan_status = models.CharField(max_length=20, default='completed')

    class Meta:
        db_table = 'exposure_scans'
        managed = False
        ordering = ['-scan_date']


class BreachMatch(models.Model):
    match_id = models.AutoField(primary_key=True)
    scan = models.ForeignKey(ExposureScan, on_delete=models.CASCADE, related_name='breach_matches')
    breach = models.ForeignKey(
        'BreachRecord',
        on_delete=models.CASCADE,
        related_name='exposure_matches',
        db_column='breach_id',
    )
    data_exposed = models.CharField(max_length=500)
    description = models.CharField(max_length=1000)

    class Meta:
        db_table = 'breach_matches'
        managed = False
        unique_together = [('scan', 'breach')]


class ExposureRecommendation(models.Model):
    recommendation_id = models.AutoField(primary_key=True)
    scan = models.ForeignKey(ExposureScan, on_delete=models.CASCADE, related_name='recommendations')
    title = models.CharField(max_length=200)
    description = models.CharField(max_length=1000)
    priority_level = models.CharField(max_length=20, default='medium')

    class Meta:
        db_table = 'recommendations'
        managed = False