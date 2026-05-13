{% extends "base.aspx" %}
{% load static %}

{% block title %}Notifications{% endblock %}

{% block content %}
<div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-4 border-bottom">
                    <h1 class="h2">Alerts</h1>
                </div>

                <div class="card content-card fade-up">
                    <div class="card-body">
                        <div class="list-group list-group-flush">
                            {% for note in notifications %}
                                <div class="list-group-item bg-transparent text-light border-secondary d-flex justify-content-between align-items-start">
                                    <div>
                                        <strong>{{ note.title }}</strong>
                                        <div class="text-muted small">{{ note.message }}</div>
                                        <div class="text-muted small">{{ note.created_at|date:"M d, Y H:i" }}</div>
                                    </div>
                                    <form method="post" action="{% url 'notification_read' note.id %}">
                                        {% csrf_token %}
                                        {% if not note.is_read %}
                                            <button class="btn btn-sm btn-outline-light">Mark Read</button>
                                        {% endif %}
                                    </form>
                                </div>
                            {% empty %}
                                <div class="text-muted">No notifications yet.</div>
                            {% endfor %}
                        </div>
                    </div>
                </div>


{% endblock %}
