{% extends "base.aspx" %}
{% load static %}

{% block title %}My Profile{% endblock %}

{% block content %}
<div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-4 border-bottom">
    <h1 class="h2 brand-logo">Profile Settings</h1>
</div>

<div class="row stagger">
    <div class="col-md-7">
        <div class="card content-card fade-up">
            <div class="card-header border-bottom-0 pt-4 pb-0">
                <h5 class="card-title fw-bold"><i class="bi bi-person-circle me-2 text-accent"></i> Personal Information</h5>
            </div>
            <div class="card-body">
                <form method="post" action="{% url 'profile' %}">
                    {% csrf_token %}
                    <div class="form-floating mb-3">
                        <input type="text" name="name" class="form-control" value="{{ user.name }}" placeholder="Full Name">
                        <label>Full Name</label>
                    </div>
                    <div class="form-floating mb-3">
                        <input type="email" name="email" class="form-control" value="{{ user.email }}" placeholder="Email" readonly>
                        <label>Email (Cannot be changed)</label>
                    </div>
                    <div class="form-floating mb-4">
                        <input type="text" name="phone" class="form-control" value="{{ user.phone|default:'' }}" placeholder="Phone">
                        <label>Phone Number</label>
                    </div>
                    <button type="submit" class="btn btn-accent w-100 py-3 rounded-3 fw-bold">Update Profile</button>
                </form>
            </div>
        </div>
    </div>
    
    <div class="col-md-5">
        <div class="card content-card fade-up h-100">
            <div class="card-header border-bottom-0 pt-4 pb-0">
                <h5 class="card-title fw-bold text-danger"><i class="bi bi-shield-lock me-2"></i> Security</h5>
            </div>
            <div class="card-body">
                <p class="text-muted small mb-4">Manage your account security and authentication settings.</p>
                
                <div class="d-grid gap-3">
                    <a href="{% url 'password_change' %}" class="btn btn-outline-light text-start py-3 px-3 rounded-3 d-flex justify-content-between align-items-center">
                        <span><i class="bi bi-key me-2"></i> Change Password</span>
                        <i class="bi bi-chevron-right small"></i>
                    </a>
                    
                    <button type="button" class="btn btn-outline-danger text-start py-3 px-3 rounded-3 d-flex justify-content-between align-items-center" data-bs-toggle="modal" data-bs-target="#deleteAccountModal">
                        <span><i class="bi bi-person-x me-2"></i> Delete Account</span>
                        <i class="bi bi-chevron-right small"></i>
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Delete Account Modal -->
<div class="modal fade" id="deleteAccountModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content glass-panel border-0">
            <div class="modal-header border-bottom-0 pt-4 px-4">
                <h5 class="modal-title fw-bold text-danger">Permanently Delete Account?</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body px-4">
                <p class="text-muted">This action is irreversible. All your companies, consents, and activity logs will be permanently wiped from the vault.</p>
            </div>
            <div class="modal-footer border-top-0 pb-4 px-4">
                <button type="button" class="btn btn-secondary flex-grow-1" data-bs-dismiss="modal">Cancel</button>
                <form action="{% url 'profile_delete' %}" method="post" class="flex-grow-1">
                    {% csrf_token %}
                    <button type="submit" class="btn btn-danger w-100 fw-bold">Yes, Delete Everything</button>
                </form>
            </div>
        </div>
    </div>
</div>
{% endblock %}
