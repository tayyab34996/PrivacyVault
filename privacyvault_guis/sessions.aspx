{% extends "base.aspx" %}
{% load static %}

{% block title %}Sessions{% endblock %}

{% block content %}
<div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-4 border-bottom">
                    <h1 class="h2">Active Sessions</h1>
                    <form method="post" action="{% url 'logout_other_sessions' %}">
                        {% csrf_token %}
                        <button class="btn btn-outline-danger">Logout Other Sessions</button>
                    </form>
                </div>

                <div class="card content-card fade-up">
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle">
                                <thead class="table-dark">
                                    <tr>
                                        <th>Session Key</th>
                                        <th>Expires</th>
                                        <th>Status</th>
                                        <th>Action</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {% for session in sessions %}
                                        <tr>
                                            <td>{{ session.session_key|slice:":10" }}...</td>
                                            <td>{{ session.expire_date|date:"M d, Y H:i" }}</td>
                                            <td>
                                                {% if session.is_current %}
                                                    <span class="badge bg-success">Current</span>
                                                {% else %}
                                                    <span class="badge bg-secondary">Active</span>
                                                {% endif %}
                                            </td>
                                            <td>
                                                {% if not session.is_current %}
                                                    <form method="post" action="{% url 'session_terminate' session.session_key %}">
                                                        {% csrf_token %}
                                                        <button class="btn btn-sm btn-outline-danger">End</button>
                                                    </form>
                                                {% else %}
                                                    <span class="text-muted">-</span>
                                                {% endif %}
                                            </td>
                                        </tr>
                                    {% empty %}
                                        <tr>
                                            <td colspan="4" class="text-muted">No sessions found.</td>
                                        </tr>
                                    {% endfor %}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>


{% endblock %}
