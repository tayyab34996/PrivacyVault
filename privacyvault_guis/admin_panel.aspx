{% extends "base.aspx" %}
{% load static %}

{% block title %}Admin Console{% endblock %}

{% block content %}
<div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-4 border-bottom">
    <h1 class="h2 text-warning brand-logo"><i class="bi bi-shield-lock me-2"></i>Admin Console</h1>
</div>

<div class="d-flex justify-content-between align-items-center mb-3 fade-up">
    <h4 class="mb-0 fw-bold">Data Categories</h4>
    <button class="btn btn-sm btn-accent shadow" data-bs-toggle="modal" data-bs-target="#addCategoryModal"><i class="bi bi-plus-lg"></i> Add Category</button>
</div>

<div class="card content-card fade-up mb-5">
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-hover align-middle">
                <thead class="table-dark">
                    <tr>
                        <th>Category Name</th>
                        <th>Sensitivity</th>
                        <th class="text-end">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    {% for category in categories %}
                        <tr>
                            <td><strong class="text-light">{{ category.category_name }}</strong></td>
                            <td>
                                {% if category.sensitivity == 'high' %}
                                    <span class="badge bg-danger bg-opacity-10 text-danger border border-danger border-opacity-25 px-3">High</span>
                                {% elif category.sensitivity == 'medium' %}
                                    <span class="badge bg-warning bg-opacity-10 text-warning border border-warning border-opacity-25 px-3">Medium</span>
                                {% else %}
                                    <span class="badge bg-success bg-opacity-10 text-success border border-success border-opacity-25 px-3">Low</span>
                                {% endif %}
                            </td>
                            <td class="text-end">
                                <div class="btn-group">
                                    <button class="btn btn-sm btn-outline-info" data-bs-toggle="modal" data-bs-target="#editCategoryModal-{{ category.category_id }}"><i class="bi bi-pencil"></i></button>
                                    <form method="post" action="{% url 'category_delete' category.category_id %}" class="d-inline">
                                        {% csrf_token %}
                                        <button class="btn btn-sm btn-outline-danger"><i class="bi bi-trash"></i></button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    {% empty %}
                        <tr>
                            <td colspan="3" class="text-center py-4 text-muted">No categories defined.</td>
                        </tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>
    </div>
</div>

<div class="d-flex justify-content-between align-items-center mb-3 fade-up">
    <h4 class="mb-0 fw-bold text-danger"><i class="bi bi-exclamation-triangle me-2"></i>Security Breaches</h4>
    <button class="btn btn-sm btn-danger shadow" data-bs-toggle="modal" data-bs-target="#addBreachModal"><i class="bi bi-shield-slash"></i> Record Breach</button>
</div>

<div class="card content-card fade-up border-danger border-opacity-25">
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-hover align-middle">
                <thead class="table-dark">
                    <tr>
                        <th>Company</th>
                        <th>Date</th>
                        <th>Severity</th>
                        <th class="text-end">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    {% for breach in breaches %}
                        <tr>
                            <td><strong class="text-light">{{ breach.company.name }}</strong></td>
                            <td class="text-muted">{{ breach.breach_date|date:"M d, Y" }}</td>
                            <td>
                                <span class="badge bg-danger bg-opacity-10 text-danger border border-danger border-opacity-25 px-3">{{ breach.severity|upper }}</span>
                            </td>
                            <td class="text-end">
                                <div class="btn-group">
                                    <button class="btn btn-sm btn-outline-info" data-bs-toggle="modal" data-bs-target="#editBreachModal-{{ breach.breach_id }}">Edit</button>
                                    <form method="post" action="{% url 'breach_delete' breach.breach_id %}" class="d-inline">
                                        {% csrf_token %}
                                        <button class="btn btn-sm btn-outline-danger"><i class="bi bi-trash"></i></button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    {% empty %}
                        <tr>
                            <td colspan="4" class="text-center py-4 text-muted">No security breaches recorded.</td>
                        </tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Modal implementations follow same glassmorphism pattern -->
{% endblock %}
