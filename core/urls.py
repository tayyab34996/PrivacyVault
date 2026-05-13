from django.urls import path
from django.contrib.auth import views as auth_views

from . import views
from .forms import CustomPasswordResetForm

urlpatterns = [
    path("", views.landing_page, name="landing"),
    path("dashboard/", views.home, name="home"),
    path("login/", views.login_view, name="login"),
    path("accounts/login/", views.login_view, name="accounts_login"),
    path("signup/", views.signup_view, name="signup"),
    path("logout/", views.logout_view, name="logout"),

    path("profile/", views.profile_view, name="profile"),
    path("profile/delete/", views.profile_delete, name="profile_delete"),

    path("companies/", views.company_list, name="companies"),
    path("companies/add/", views.company_create, name="company_add"),
    path("companies/import/", views.company_import, name="company_import"),
    path("companies/<int:company_id>/edit/", views.company_update, name="company_edit"),
    path("companies/<int:company_id>/delete/", views.company_delete, name="company_delete"),
    path("companies/<int:company_id>/rate/", views.rating_upsert, name="company_rate"),

    path("consents/", views.consent_list, name="consents"),
    path("consents/add/", views.consent_create, name="consent_add"),
    path("consents/import/", views.consent_import, name="consent_import"),
    path("consents/<int:consent_id>/edit/", views.consent_update, name="consent_edit"),
    path("consents/<int:consent_id>/delete/", views.consent_delete, name="consent_delete"),

    path("requests/", views.deletion_request_list, name="requests"),
    path("requests/add/", views.deletion_request_create, name="request_add"),
    path("requests/<int:request_id>/edit/", views.deletion_request_update, name="request_edit"),
    path("requests/<int:request_id>/delete/", views.deletion_request_delete, name="request_delete"),

    path("admin-panel/", views.admin_panel, name="admin_panel"),
    path("admin-panel/categories/add/", views.data_category_create, name="category_add"),
    path("admin-panel/categories/<int:category_id>/edit/", views.data_category_update, name="category_edit"),
    path("admin-panel/categories/<int:category_id>/delete/", views.data_category_delete, name="category_delete"),
    path("admin-panel/breaches/add/", views.breach_create, name="breach_add"),
    path("admin-panel/breaches/<int:breach_id>/edit/", views.breach_update, name="breach_edit"),
    path("admin-panel/breaches/<int:breach_id>/delete/", views.breach_delete, name="breach_delete"),

    path("breaches/", views.breach_history, name="breach_history"),
    path("notifications/", views.notifications_list, name="notifications"),
    path("notifications/<int:notification_id>/read/", views.notification_mark_read, name="notification_read"),
    path("activity/", views.activity_log_view, name="activity_log"),

    path("sessions/", views.session_list, name="sessions"),
    path("sessions/logout-others/", views.logout_other_sessions, name="logout_other_sessions"),
    path("sessions/<str:session_key>/end/", views.session_terminate, name="session_terminate"),

    path("export/", views.export_report, name="export_report"),

    path("exposure/", views.exposure_scan_view, name="exposure_scan"),

    path(
        "password-reset/",
        auth_views.PasswordResetView.as_view(
            template_name="passwords/password_reset_form.aspx",
            form_class=CustomPasswordResetForm,
            email_template_name="passwords/password_reset_email.txt",
            html_email_template_name="passwords/password_reset_email.html",
            subject_template_name="passwords/password_reset_subject.txt",
            success_url="/password-reset/done/",
        ),
        name="password_reset",
    ),
    path(
        "password-reset/done/",
        auth_views.PasswordResetDoneView.as_view(
            template_name="passwords/password_reset_done.aspx",
        ),
        name="password_reset_done",
    ),
    path(
        "password-reset/confirm/<uidb64>/<token>/",
        auth_views.PasswordResetConfirmView.as_view(
            template_name="passwords/password_reset_confirm.aspx",
            success_url="/password-reset/complete/",
        ),
        name="password_reset_confirm",
    ),
    path(
        "password-reset/complete/",
        auth_views.PasswordResetCompleteView.as_view(
            template_name="passwords/password_reset_complete.aspx",
        ),
        name="password_reset_complete",
    ),
    path(
        "password-change/",
        auth_views.PasswordChangeView.as_view(
            template_name="passwords/password_change_form.aspx",
            success_url="/password-change/done/",
        ),
        name="password_change",
    ),
    path(
        "password-change/done/",
        auth_views.PasswordChangeDoneView.as_view(
            template_name="passwords/password_change_done.aspx",
        ),
        name="password_change_done",
    ),
]
