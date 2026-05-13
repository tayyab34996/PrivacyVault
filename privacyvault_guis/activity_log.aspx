{% extends "base.aspx" %}
{% load static %}

{% block title %}Activity Log{% endblock %}

{% block content %}
<div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-4 border-bottom">
                    <h1 class="h2">Activity Log</h1>
                </div>

                <div class="card content-card mb-4 fade-up">
                    <div class="card-body">
                        <form method="get" class="row g-3 align-items-end">
                            <div class="col-md-3">
                                <label class="form-label text-muted">Action</label>
                                <input type="text" name="action" class="form-control" value="{{ filters.action }}">
                            </div>
                            <div class="col-md-2">
                                <label class="form-label text-muted">Start Date</label>
                                <input type="date" name="start_date" class="form-control" value="{{ filters.start_date }}">
                            </div>
                            <div class="col-md-2">
                                <label class="form-label text-muted">End Date</label>
                                <input type="date" name="end_date" class="form-control" value="{{ filters.end_date }}">
                            </div>
                            {% if request.user.is_staff %}
                                <div class="col-md-2">
                                    <label class="form-label text-muted">Scope</label>
                                    <select name="scope" class="form-select">
                                        <option value="">My Activity</option>
                                        <option value="all" {% if filters.scope == 'all' %}selected{% endif %}>All Users</option>
                                    </select>
                                </div>
                            {% endif %}
                            <div class="col-12">
                                <button class="btn btn-outline-light">Apply</button>
                                <a class="btn btn-link text-decoration-none" href="{% url 'activity_log' %}">Reset</a>
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
                                        <th>Date</th>
                                        <th>User</th>
                                        <th>Action</th>
                                        <th>Table</th>
                                        <th>Details</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {% for log in logs %}
                                        <tr>
                                            <td>{{ log.created_at|date:"M d, Y H:i" }}</td>
                                            <td>{{ log.user.email }}</td>
                                            <td>{{ log.action_type }}</td>
                                            <td>{{ log.table_name|default:"-" }}</td>
                                            <td>{{ log.description|default:"-" }}</td>
                                        </tr>
                                    {% empty %}
                                        <tr>
                                            <td colspan="5" class="text-muted">No activity found.</td>
                                        </tr>
                                    {% endfor %}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>


{% endblock %}
