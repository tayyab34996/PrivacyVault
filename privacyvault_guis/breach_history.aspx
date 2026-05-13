{% extends "base.aspx" %}
{% load static %}

{% block title %}Breach History{% endblock %}

{% block content %}
<div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-4 border-bottom">
                    <h1 class="h2">Breach History</h1>
                </div>

                <div class="card content-card mb-4 fade-up">
                    <div class="card-body">
                        <form method="get" class="row g-3 align-items-end">
                            <div class="col-md-4">
                                <label class="form-label text-muted">Company</label>
                                <select name="company" class="form-select">
                                    <option value="">All</option>
                                    {% for company in companies %}
                                        <option value="{{ company.company_id }}" {% if filters.company == company.company_id|stringformat:"s" %}selected{% endif %}>{{ company.name }}</option>
                                    {% endfor %}
                                </select>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label text-muted">Severity</label>
                                <select name="severity" class="form-select">
                                    <option value="">All</option>
                                    <option value="low" {% if filters.severity == 'low' %}selected{% endif %}>Low</option>
                                    <option value="medium" {% if filters.severity == 'medium' %}selected{% endif %}>Medium</option>
                                    <option value="high" {% if filters.severity == 'high' %}selected{% endif %}>High</option>
                                </select>
                            </div>
                            <div class="col-12">
                                <button class="btn btn-outline-light">Apply</button>
                                <a class="btn btn-link text-decoration-none" href="{% url 'breach_history' %}">Reset</a>
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
                                        <th>Company</th>
                                        <th>Date</th>
                                        <th>Severity</th>
                                        <th>Details</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {% for breach in breaches %}
                                        <tr>
                                            <td>{{ breach.company.name }}</td>
                                            <td>{{ breach.breach_date|date:"M d, Y" }}</td>
                                            <td>
                                                {% if breach.severity == 'high' %}
                                                    <span class="badge bg-danger">High</span>
                                                {% elif breach.severity == 'medium' %}
                                                    <span class="badge bg-warning text-dark">Medium</span>
                                                {% else %}
                                                    <span class="badge bg-success">Low</span>
                                                {% endif %}
                                            </td>
                                            <td>{{ breach.description }}</td>
                                        </tr>
                                    {% empty %}
                                        <tr>
                                            <td colspan="4" class="text-muted">No breach records.</td>
                                        </tr>
                                    {% endfor %}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>


{% endblock %}
