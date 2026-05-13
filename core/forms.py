from django import forms
from django.contrib.auth.forms import PasswordResetForm, UserCreationForm
from django.core.validators import FileExtensionValidator

from .models import (
    BreachRecord,
    Company,
    ConsentRecord,
    CustomUser,
    DataCategory,
    DeletionRequest,
    Rating,
)


class ExposureScanForm(forms.Form):
    email = forms.EmailField(
        required=True,
        widget=forms.EmailInput(attrs={'class': 'form-control', 'placeholder': 'Email to check'}),
    )
    phone = forms.CharField(
        required=False,
        max_length=30,
        widget=forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Phone (optional)'}),
    )
    usernames = forms.CharField(
        required=False,
        max_length=500,
        widget=forms.TextInput(
            attrs={
                'class': 'form-control',
                'placeholder': 'Usernames, comma-separated (optional)',
            }
        ),
        help_text='Optional. Used only against company names in our on-file breach list — not a live people search.',
    )

class UserRegistrationForm(UserCreationForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.existing_user = None

    email = forms.EmailField(
        required=True,
        widget=forms.EmailInput(attrs={'class': 'form-control', 'placeholder': 'Email'})
    )
    name = forms.CharField(
        max_length=150,
        widget=forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Full Name'})
    )
    phone_number = forms.CharField(
        required=False,
        widget=forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Phone Number'})
    )
    password1 = forms.CharField(
        label='Password',
        widget=forms.PasswordInput(attrs={'class': 'form-control', 'placeholder': 'Password'})
    )
    password2 = forms.CharField(
        label='Confirm Password',
        widget=forms.PasswordInput(attrs={'class': 'form-control', 'placeholder': 'Confirm Password'})
    )

    class Meta:
        model = CustomUser
        fields = ('email', 'name', 'phone_number', 'password1', 'password2')

    def clean_email(self):
        email = (self.cleaned_data.get('email') or '').lower()
        existing_user = CustomUser.objects.filter(email__iexact=email).first()
        if existing_user:
            if existing_user.is_active:
                raise forms.ValidationError('This email is already in use.')
            self.existing_user = existing_user
            self.instance = existing_user
        return email


class UserLoginForm(forms.Form):
    email = forms.EmailField(
        widget=forms.EmailInput(attrs={'class': 'form-control', 'placeholder': 'Email'})
    )
    password = forms.CharField(
        widget=forms.PasswordInput(attrs={'class': 'form-control', 'placeholder': 'Password'}),
        strip=False
    )


class ProfileUpdateForm(forms.ModelForm):
    class Meta:
        model = CustomUser
        fields = ('name', 'email', 'phone_number')
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-control'}),
            'email': forms.EmailInput(attrs={'class': 'form-control'}),
            'phone_number': forms.TextInput(attrs={'class': 'form-control'}),
        }


class CompanyForm(forms.ModelForm):
    class Meta:
        model = Company
        fields = ('name', 'website', 'category')
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-control'}),
            'website': forms.URLInput(attrs={'class': 'form-control'}),
            'category': forms.TextInput(attrs={'class': 'form-control'}),
        }


class DataCategoryForm(forms.ModelForm):
    class Meta:
        model = DataCategory
        fields = ('category_name', 'sensitivity')
        widgets = {
            'category_name': forms.TextInput(attrs={'class': 'form-control'}),
            'sensitivity': forms.Select(attrs={'class': 'form-select'}),
        }


class ConsentRecordForm(forms.ModelForm):
    class Meta:
        model = ConsentRecord
        fields = ('company', 'data_categories', 'expiry_date')
        widgets = {
            'company': forms.Select(attrs={'class': 'form-select'}),
            'data_categories': forms.SelectMultiple(attrs={'class': 'form-select', 'size': 6}),
            'expiry_date': forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}),
        }


class DeletionRequestForm(forms.ModelForm):
    class Meta:
        model = DeletionRequest
        fields = ('company', 'target_data', 'status', 'response_date', 'note')
        widgets = {
            'company': forms.Select(attrs={'class': 'form-select'}),
            'target_data': forms.TextInput(attrs={'class': 'form-control'}),
            'status': forms.Select(attrs={'class': 'form-select'}),
            'response_date': forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}),
            'note': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
        }


class RatingForm(forms.ModelForm):
    class Meta:
        model = Rating
        fields = ('rating', 'review')
        widgets = {
            'rating': forms.Select(attrs={'class': 'form-select'}),
            'review': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
        }


class BreachRecordForm(forms.ModelForm):
    class Meta:
        model = BreachRecord
        fields = ('company', 'breach_date', 'severity', 'description')
        widgets = {
            'company': forms.Select(attrs={'class': 'form-select'}),
            'breach_date': forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}),
            'severity': forms.Select(attrs={'class': 'form-select'}),
            'description': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
        }


class CSVImportForm(forms.Form):
    csv_file = forms.FileField(
        label='CSV file',
        help_text='Only .csv files are accepted.',
        validators=[FileExtensionValidator(['csv'], message='Upload a file whose name ends with .csv')],
        widget=forms.FileInput(
            attrs={
                'class': 'form-control',
                'accept': '.csv,text/csv',
            }
        ),
    )

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data


class CustomPasswordResetForm(PasswordResetForm):
    def get_users(self, email):
        email = (email or '').strip()
        if not email:
            return []
        return (
            CustomUser._default_manager.filter(email__iexact=email, account_status='active')
            .iterator()
        )