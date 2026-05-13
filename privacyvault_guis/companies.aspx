{% extends "base.aspx" %}
{% load static %}

{% block title %}My Companies{% endblock %}

{% block content %}
<div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-4 border-bottom">
    <h1 class="h2 brand-logo">My Companies</h1>
    <div class="d-flex gap-2">
        <button type="button" class="btn btn-outline-light rounded-3" data-bs-toggle="modal" data-bs-target="#importCompanyModal">
            <i class="bi bi-upload"></i> Import CSV
        </button>
        <button type="button" class="btn btn-accent rounded-3 shadow" data-bs-toggle="modal" data-bs-target="#addCompanyModal">
            <i class="bi bi-plus-lg"></i> Add Company
        </button>
    </div>
</div>

<div class="row mb-4 fade-up">
    <div class="col-md-6">
        <form method="get" class="d-flex gap-2">
            <div class="input-group">
                <span class="input-group-text bg-transparent border-secondary text-muted"><i class="bi bi-search"></i></span>
                <input type="text" name="q" class="form-control border-secondary" value="{{ search_query }}" placeholder="Search companies...">
                <button class="btn btn-outline-primary" type="submit">Search</button>
            </div>
        </form>
    </div>
</div>

<div class="card content-card fade-up">
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-hover align-middle">
                <thead class="table-dark">
                    <tr>
                        <th>Company Name</th>
                        <th>Category</th>
                        <th>Trust Rating</th>
                        <th class="text-end">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    {% for company in companies %}
                        <tr>
                            <td>
                                <strong class="text-light">{{ company.name }}</strong>
                                {% if company.breaches_count > 0 %}
                                    <span class="badge bg-danger ms-2" style="font-size: 0.7rem;">BREACH ALERT</span>
                                {% endif %}
                            </td>
                            <td><span class="badge-soft">{{ company.category|default:"General" }}</span></td>
                            <td>
                                {% if company.avg_rating %}
                                    <div class="text-warning">
                                        <i class="bi bi-star-fill"></i> {{ company.avg_rating|floatformat:1 }}
                                    </div>
                                {% else %}
                                    <span class="text-muted small">No ratings</span>
                                {% endif %}
                            </td>
                            <td class="text-end">
                                <div class="btn-group">
                                    <button class="btn btn-sm btn-outline-warning" data-bs-toggle="modal" data-bs-target="#rateCompanyModal-{{ company.company_id }}"><i class="bi bi-star"></i></button>
                                    <button class="btn btn-sm btn-outline-info" data-bs-toggle="modal" data-bs-target="#editCompanyModal-{{ company.company_id }}"><i class="bi bi-pencil"></i></button>
                                    <form method="post" action="{% url 'company_delete' company.company_id %}" class="d-inline">
                                        {% csrf_token %}
                                        <button class="btn btn-sm btn-outline-danger" onclick="return confirm('Remove this company?')"><i class="bi bi-trash"></i></button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    {% empty %}
                        <tr>
                            <td colspan="5" class="text-center py-5 text-muted">No companies found in your vault.</td>
                        </tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Modals -->
{% for company in companies %}
    <!-- Rate Modal -->
    <div class="modal fade" id="rateCompanyModal-{{ company.company_id }}" tabindex="-1">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content glass-panel border-0">
                <div class="modal-header border-bottom-0 pt-4 px-4">
                    <h5 class="modal-title fw-bold">Rate {{ company.name }}</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <form method="post" action="{% url 'company_rate' company.company_id %}">
                    {% csrf_token %}
                    <div class="modal-body px-4">
                        <div class="mb-3">
                            <label class="form-label text-muted small fw-bold">YOUR RATING</label>
                            <div class="d-flex justify-content-between">
                                {% for i in "12345" %}
                                    <input type="radio" class="btn-check" name="rating" id="star-{{ company.company_id }}-{{ forloop.counter }}" value="{{ forloop.counter }}" required>
                                    <label class="btn btn-outline-warning rounded-circle" for="star-{{ company.company_id }}-{{ forloop.counter }}" style="width: 45px; height: 45px; display:flex; align-items:center; justify-content:center;">{{ forloop.counter }}</label>
                                {% endfor %}
                            </div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label text-muted small fw-bold">REVIEW</label>
                            <textarea name="review" class="form-control" rows="3" placeholder="Describe their privacy handling..."></textarea>
                        </div>
                    </div>
                    <div class="modal-footer border-top-0 pb-4 px-4">
                        <button type="submit" class="btn btn-accent w-100 py-2 fw-bold">Submit Rating</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
{% endfor %}

<!-- Add Company Modal -->
<div class="modal fade" id="addCompanyModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content glass-panel border-0">
            <div class="modal-header border-bottom-0 pt-4 px-4">
                <h5 class="modal-title fw-bold">Add New Service</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <form method="post" action="{% url 'company_add' %}">
                {% csrf_token %}
                <div class="modal-body px-4">
                    <div class="form-floating mb-3">
                        {{ add_form.name }}
                        <label>Company Name</label>
                    </div>
                    <div class="form-floating mb-3">
                        {{ add_form.website }}
                        <label>Website URL</label>
                    </div>
                    <div class="form-floating">
                        {{ add_form.category }}
                        <label>Category (e.g. Social, Cloud)</label>
                    </div>
                </div>
                <div class="modal-footer border-top-0 pb-4 px-4">
                    <button type="submit" class="btn btn-accent w-100 py-2 fw-bold">Save to Vault</button>
                </div>
            </form>
        </div>
    </div>
</div>
{% endblock %}
