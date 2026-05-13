{% extends "base.aspx" %}
{% load static %}

{% block title %}Consent Records{% endblock %}

{% block content %}
<div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-4 border-bottom">
    <h1 class="h2 brand-logo">Privacy Consents</h1>
    <div class="d-flex gap-2">
        <button type="button" class="btn btn-outline-light rounded-3" data-bs-toggle="modal" data-bs-target="#importConsentModal">
            <i class="bi bi-upload"></i> Import CSV
        </button>
        <button type="button" class="btn btn-accent rounded-3 shadow" data-bs-toggle="modal" data-bs-target="#addConsentModal">
            <i class="bi bi-plus-lg"></i> Record New Consent
        </button>
    </div>
</div>

<div class="card content-card mb-4 fade-up">
    <div class="card-body">
        <form method="get" class="row g-3 align-items-end">
            <div class="col-md-3">
                <label class="form-label text-muted small fw-bold">DATA CATEGORY</label>
                <select name="category" class="form-select">
                    <option value="">All Categories</option>
                    {% for category in categories %}
                        <option value="{{ category.category_id }}" {% if filters.category == category.category_id|stringformat:"s" %}selected{% endif %}>{{ category.category_name }}</option>
                    {% endfor %}
                </select>
            </div>
            <div class="col-md-3">
                <label class="form-label text-muted small fw-bold">EXPIRY STATUS</label>
                <select name="expiry" class="form-select">
                    <option value="">All Statuses</option>
                    <option value="upcoming" {% if filters.expiry == 'upcoming' %}selected{% endif %}>Upcoming</option>
                    <option value="expired" {% if filters.expiry == 'expired' %}selected{% endif %}>Expired</option>
                </select>
            </div>
            <div class="col-md-4">
                <button class="btn btn-outline-primary" type="submit">Apply Filters</button>
                <a class="btn btn-link text-decoration-none text-muted small" href="{% url 'consents' %}">Clear All</a>
            </div>
        </form>
    </div>
</div>

<div class="card content-card fade-up">
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-hover align-middle mt-2">
                <thead class="table-dark">
                    <tr>
                        <th>Company</th>
                        <th>Categories Shared</th>
                        <th>Expiry Date</th>
                        <th>Status</th>
                        <th class="text-end">Action</th>
                    </tr>
                </thead>
                <tbody>
                    {% for row in consent_rows %}
                        {% with consent=row.consent %}
                        <tr>
                            <td><strong class="text-light">{{ consent.company.name }}</strong></td>
                            <td>
                                {% for category in consent.data_categories.all %}
                                    <span class="badge-soft me-1">{{ category.category_name }}</span>
                                {% empty %}
                                    <span class="text-muted small">None</span>
                                {% endfor %}
                            </td>
                            <td>
                                {% if consent.expiry_date %}
                                    <span class="text-info">{{ consent.expiry_date|date:"M d, Y" }}</span>
                                {% else %}
                                    <span class="text-muted italic">Permanent</span>
                                {% endif %}
                            </td>
                            <td><span class="badge bg-success bg-opacity-10 text-success border border-success border-opacity-25 px-3">Active</span></td>
                            <td class="text-end">
                                <div class="btn-group">
                                    <button type="button" class="btn btn-sm btn-outline-info" data-bs-toggle="modal" data-bs-target="#editConsentModal-{{ consent.consent_id }}"><i class="bi bi-pencil"></i></button>
                                    <form method="post" action="{% url 'consent_delete' consent.consent_id %}" class="d-inline">
                                        {% csrf_token %}
                                        <button type="submit" class="btn btn-sm btn-outline-danger" onclick="return confirm('Delete this consent record?')"><i class="bi bi-trash"></i></button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                        {% endwith %}
                    {% empty %}
                        <tr>
                            <td colspan="5" class="text-center py-5 text-muted">No active consents found.</td>
                        </tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>
    </div>
</div>

{% for row in consent_rows %}
<div class="modal fade" id="editConsentModal-{{ row.consent.consent_id }}" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content glass-panel border-0">
            <div class="modal-header border-bottom-0 pt-4 px-4">
                <h5 class="modal-title fw-bold">Edit consent — {{ row.consent.company.name }}</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <form method="post" action="{% url 'consent_edit' row.consent.consent_id %}">
                {% csrf_token %}
                <div class="modal-body px-4">
                    <div class="mb-3">
                        <label class="form-label text-muted small fw-bold">COMPANY</label>
                        {{ row.edit_form.company }}
                    </div>
                    <div class="mb-3">
                        <label class="form-label text-muted small fw-bold">DATA CATEGORIES</label>
                        {{ row.edit_form.data_categories }}
                    </div>
                    <div class="mb-3">
                        <label class="form-label text-muted small fw-bold">EXPIRY DATE</label>
                        {{ row.edit_form.expiry_date }}
                    </div>
                </div>
                <div class="modal-footer border-top-0 pb-4 px-4">
                    <button type="submit" class="btn btn-accent w-100 py-2 fw-bold">Save changes</button>
                </div>
            </form>
        </div>
    </div>
</div>
{% endfor %}

<div class="modal fade" id="addConsentModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content glass-panel border-0">
            <div class="modal-header border-bottom-0 pt-4 px-4">
                <h5 class="modal-title fw-bold">Record new consent</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <form method="post" action="{% url 'consent_add' %}">
                {% csrf_token %}
                <div class="modal-body px-4">
                    <p class="text-muted small">Choose a company you have linked, one or more data categories, and an optional expiry date.</p>
                    <div class="mb-3">
                        <label class="form-label text-muted small fw-bold">COMPANY</label>
                        {{ consent_form.company }}
                    </div>
                    <div class="mb-3">
                        <label class="form-label text-muted small fw-bold">DATA CATEGORIES</label>
                        {{ consent_form.data_categories }}
                    </div>
                    <div class="mb-3">
                        <label class="form-label text-muted small fw-bold">EXPIRY DATE (optional)</label>
                        {{ consent_form.expiry_date }}
                    </div>
                </div>
                <div class="modal-footer border-top-0 pb-4 px-4">
                    <button type="submit" class="btn btn-accent w-100 py-2 fw-bold">Save consent</button>
                </div>
            </form>
        </div>
    </div>
</div>

<div class="modal fade" id="importConsentModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content glass-panel border-0">
            <div class="modal-header border-bottom-0 pt-4 px-4">
                <h5 class="modal-title fw-bold">Import consents (CSV)</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <form method="post" action="{% url 'consent_import' %}" enctype="multipart/form-data">
                {% csrf_token %}
                <div class="modal-body px-4">
                    <p class="text-muted small">UTF-8 CSV with header row. Columns:</p>
                    <ul class="text-muted small">
                        <li><code>company</code> — required</li>
                        <li><code>data_categories</code> — comma-separated category names (required for a row to import)</li>
                        <li><code>expiry_date</code> — optional, <code>YYYY-MM-DD</code></li>
                    </ul>
                    <div class="mb-3">
                        <label class="form-label text-muted small fw-bold">CSV FILE</label>
                        {{ import_form.csv_file }}
                    </div>
                </div>
                <div class="modal-footer border-top-0 pb-4 px-4">
                    <button type="submit" class="btn btn-accent w-100 py-2 fw-bold">Upload and import</button>
                </div>
            </form>
        </div>
    </div>
</div>
{% endblock %}
