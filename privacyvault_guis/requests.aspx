{% extends "base.aspx" %}
{% load static %}

{% block title %}Requests{% endblock %}

{% block content %}
<div
                    class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-4 border-bottom">
                    <h1 class="h2">Data Deletion Requests</h1>
                    <button class="btn btn-accent" data-bs-toggle="modal" data-bs-target="#addRequestModal"><i class="bi bi-send"></i> New Deletion Request</button>
                </div>
                {% if messages %}
                    {% for message in messages %}
                        <div class="alert alert-info">{{ message }}</div>
                    {% endfor %}
                {% endif %}
                <div class="card content-card fade-up">
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle">
                                <thead class="table-dark">
                                    <tr>
                                        <th>Company</th>
                                        <th>Request Date</th>
                                        <th>Target Data</th>
                                        <th>Status</th>
                                        <th>Response Date</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {% for req in requests %}
                                        <tr>
                                            <td><strong>{{ req.company.name }}</strong></td>
                                            <td>{{ req.request_date|date:"M d, Y" }}</td>
                                            <td>{{ req.target_data|default:"-" }}</td>
                                            <td>
                                                {% if req.status == 'pending' %}
                                                    <i class="bi bi-hourglass-split text-warning"></i> <span class="text-warning">Pending</span>
                                                {% elif req.status == 'completed' %}
                                                    <i class="bi bi-check-circle text-success"></i> <span class="text-success">Completed</span>
                                                {% else %}
                                                    <i class="bi bi-x-circle text-danger"></i> <span class="text-danger">Rejected</span>
                                                {% endif %}
                                            </td>
                                            <td>{{ req.response_date|date:"M d, Y"|default:"-" }}</td>
                                            <td class="d-flex gap-2">
                                                <button class="btn btn-sm btn-outline-secondary" data-bs-toggle="modal"
                                                    data-bs-target="#editRequestModal-{{ req.request_id }}">Update</button>
                                                <form method="post" action="{% url 'request_delete' req.request_id %}">
                                                    {% csrf_token %}
                                                    <button class="btn btn-sm btn-outline-danger"><i class="bi bi-trash"></i>
                                                        Delete</button>
                                                </form>
                                            </td>
                                        </tr>
                                    {% empty %}
                                        <tr>
                                            <td colspan="6" class="text-muted">No deletion requests yet.</td>
                                        </tr>
                                    {% endfor %}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

<div class="modal fade" id="addRequestModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content border-0 shadow">
                <div class="modal-header bg-dark border-bottom-0">
                    <h5 class="modal-title">New Deletion Request</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body bg-dark">
                    <form method="post" action="{% url 'request_add' %}">
                        {% csrf_token %}
                        <div class="mb-3">
                            <label class="form-label text-muted">Company</label>
                            {{ request_form.company }}
                        </div>
                        <div class="mb-3">
                            <label class="form-label text-muted">Target Data</label>
                            {{ request_form.target_data }}
                        </div>
                        <div class="mb-3">
                            <label class="form-label text-muted">Status</label>
                            {{ request_form.status }}
                        </div>
                        <div class="mb-3">
                            <label class="form-label text-muted">Response Date</label>
                            {{ request_form.response_date }}
                        </div>
                        <div class="mb-3">
                            <label class="form-label text-muted">Note</label>
                            {{ request_form.note }}
                        </div>
                        <div class="modal-footer bg-dark border-top-0">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                            <button type="submit" class="btn btn-accent">Save Request</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    {% for req in requests %}
        <div class="modal fade" id="editRequestModal-{{ req.request_id }}" tabindex="-1">
            <div class="modal-dialog">
                <div class="modal-content border-0 shadow">
                    <div class="modal-header bg-dark border-bottom-0">
                        <h5 class="modal-title">Update Request</h5>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body bg-dark">
                        <form method="post" action="{% url 'request_edit' req.request_id %}">
                            {% csrf_token %}
                            <div class="mb-3">
                                <label class="form-label text-muted">Company</label>
                                <select name="company" class="form-select">
                                    <option value="{{ req.company.company_id }}">{{ req.company.name }}</option>
                                </select>
                            </div>
                            <div class="mb-3">
                                <label class="form-label text-muted">Target Data</label>
                                <input type="text" name="target_data" class="form-control" value="{{ req.target_data }}">
                            </div>
                            <div class="mb-3">
                                <label class="form-label text-muted">Status</label>
                                <select name="status" class="form-select">
                                    {% for value, label in status_choices %}
                                        <option value="{{ value }}" {% if value == req.status %}selected{% endif %}>{{ label }}</option>
                                    {% endfor %}
                                </select>
                            </div>
                            <div class="mb-3">
                                <label class="form-label text-muted">Response Date</label>
                                <input type="date" name="response_date" class="form-control" value="{{ req.response_date|date:'Y-m-d' }}">
                            </div>
                            <div class="mb-3">
                                <label class="form-label text-muted">Note</label>
                                <textarea name="note" class="form-control" rows="3">{{ req.note }}</textarea>
                            </div>
                            <div class="modal-footer bg-dark border-top-0">
                                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                                <button type="submit" class="btn btn-accent">Update</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    {% endfor %}
{% endblock %}
