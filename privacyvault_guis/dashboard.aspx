{% extends "base.aspx" %}
{% load static %}

{% block title %}Dashboard{% endblock %}

{% block content %}
<div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-4 border-bottom">
    <h1 class="h2 brand-logo">Dashboard Summary</h1>
    <div class="btn-toolbar mb-2 mb-md-0">
        <div class="btn-group">
            <button type="button" class="btn btn-sm btn-outline-primary dropdown-toggle" data-bs-toggle="dropdown">
                <i class="bi bi-download"></i> Export Report
            </button>
            <ul class="dropdown-menu dropdown-menu-dark">
                <li><a class="dropdown-item" href="{% url 'export_report' %}?format=csv">Export CSV</a></li>
                <li><a class="dropdown-item" href="{% url 'export_report' %}?format=pdf">Export PDF</a></li>
            </ul>
        </div>
    </div>
</div>

<div class="row mb-4 stagger">
    <div class="col-md-4 mb-3">
        <div class="card stat-card text-center p-4 h-100 card-glow fade-up">
            <h6 class="text-muted text-uppercase mb-3 small fw-bold">Privacy Risk Score</h6>
            <div class="risk-score">{{ risk_score }}<span style="font-size: 1rem; color:var(--text-muted);">/100</span></div>
            <p class="small text-danger mt-2"><i class="bi bi-arrow-up-circle"></i> Exposure indicator</p>
        </div>
    </div>
    <div class="col-md-8">
        <div class="row">
            <div class="col-sm-6 mb-3">
                <div class="card stat-card p-3 border-start border-4 border-primary fade-up">
                    <div class="text-muted small">Companies Storing Data</div>
                    <h3 class="fw-bold">{{ companies_count }}</h3>
                </div>
            </div>
            <div class="col-sm-6 mb-3">
                <div class="card stat-card p-3 border-start border-4 border-success fade-up">
                    <div class="text-muted small">Active Consents</div>
                    <h3 class="fw-bold">{{ active_consents_count }}</h3>
                </div>
            </div>
            <div class="col-sm-6 mb-3">
                <div class="card stat-card p-3 border-start border-4 border-warning fade-up">
                    <div class="text-muted small">Expired Consents</div>
                    <h3 class="fw-bold">{{ expired_consents_count }}</h3>
                </div>
            </div>
            <div class="col-sm-6 mb-3">
                <div class="card stat-card p-3 border-start border-4 border-info fade-up">
                    <div class="text-muted small">Pending Deletion Requests</div>
                    <h3 class="fw-bold">{{ pending_requests_count }}</h3>
                </div>
            </div>
        </div>
    </div>
</div>

{% if exposure_db_ready %}
<div class="row mb-4 stagger">
    <div class="col-12 mb-3">
        <h5 class="fw-bold text-uppercase small text-muted mb-3"><i class="bi bi-radar me-2"></i> Known exposure monitoring</h5>
    </div>
    {% if not exposure_has_scans %}
    <div class="col-12 mb-3">
        <div class="card border-primary border-opacity-50 bg-primary bg-opacity-10 fade-up">
            <div class="card-body d-flex flex-wrap align-items-center justify-content-between gap-3">
                <div>
                    <h5 class="fw-bold mb-1">Start your first exposure scan</h5>
                    <p class="text-muted small mb-0">Correlate an email (and optional phone/usernames) with breach records stored in PrivacyVault — not live dark-web monitoring.</p>
                </div>
                <a href="{% url 'exposure_scan' %}" class="btn btn-primary"><i class="bi bi-shield-check me-1"></i> Run scan</a>
            </div>
        </div>
    </div>
    {% endif %}
    <div class="col-md-3 mb-3">
        <div class="card stat-card p-3 h-100 border-start border-4 {% if exposure_band_key == 'high' %}border-danger{% elif exposure_band_key == 'medium' %}border-warning{% elif exposure_band_key %}border-success{% else %}border-secondary{% endif %} fade-up">
            <div class="text-muted small">Exposure score (latest scan)</div>
            <h3 class="fw-bold">{% if exposure_score is not None %}{{ exposure_score }}<span class="fs-6 text-muted">/100</span>{% else %}—{% endif %}</h3>
            {% if exposure_band_label %}<span class="badge bg-secondary bg-opacity-25">{{ exposure_band_label }}</span>{% endif %}
        </div>
    </div>
    <div class="col-md-3 mb-3">
        <div class="card stat-card p-3 h-100 border-start border-4 border-danger border-opacity-50 fade-up">
            <div class="text-muted small">Breach matches (all scans)</div>
            <h3 class="fw-bold">{{ exposure_total_breach_matches }}</h3>
        </div>
    </div>
    <div class="col-md-6 mb-3">
        <div class="card stat-card p-3 h-100 fade-up">
            <div class="text-muted small mb-2">Recent scans</div>
            {% if exposure_recent_scans %}
            <ul class="list-unstyled mb-0 small">
                {% for es in exposure_recent_scans %}
                <li class="d-flex justify-content-between border-bottom border-secondary border-opacity-25 py-1">
                    <span class="text-truncate me-2">{{ es.email_checked|truncatechars:28 }}</span>
                    <span class="text-nowrap text-muted">{{ es.scan_date|date:"M d, H:i" }}</span>
                    <a href="{% url 'exposure_scan' %}?scan_id={{ es.scan_id }}" class="ms-2">View</a>
                </li>
                {% endfor %}
            </ul>
            {% else %}
            <p class="text-muted small mb-0">No scans yet.</p>
            {% endif %}
        </div>
    </div>
</div>

<div class="row mb-4 stagger">
    <div class="col-lg-7 mb-3">
        <div class="card content-card fade-up h-100">
            <div class="card-header border-bottom-0 pt-4 pb-0">
                <h5 class="card-title fw-bold"><i class="bi bi-exclamation-octagon me-2 text-danger"></i> High-risk breach matches</h5>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-sm table-hover align-middle">
                        <thead class="table-dark">
                            <tr>
                                <th>Company</th>
                                <th>Date</th>
                                <th>Scan</th>
                            </tr>
                        </thead>
                        <tbody>
                            {% for hm in exposure_high_risk_matches %}
                            <tr>
                                <td><strong>{{ hm.breach.company.name }}</strong></td>
                                <td class="text-muted">{{ hm.breach.breach_date|date:"M d, Y" }}</td>
                                <td><a href="{% url 'exposure_scan' %}?scan_id={{ hm.scan.scan_id }}">#{{ hm.scan.scan_id }}</a></td>
                            </tr>
                            {% empty %}
                            <tr>
                                <td colspan="3" class="text-center text-muted py-3">No high-severity matches recorded yet.</td>
                            </tr>
                            {% endfor %}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
    <div class="col-lg-5 mb-3">
        <div class="card content-card fade-up h-100">
            <div class="card-header border-bottom-0 pt-4 pb-0">
                <h5 class="card-title fw-bold"><i class="bi bi-lightbulb me-2 text-warning"></i> Recommended actions (latest scan)</h5>
            </div>
            <div class="card-body">
                {% for rec in exposure_recommended_actions %}
                <div class="mb-3 pb-3 border-bottom border-secondary border-opacity-25">
                    <div class="d-flex justify-content-between gap-2">
                        <strong class="small">{{ rec.title }}</strong>
                        {% if rec.priority_level == 'high' %}<span class="badge bg-danger">High</span>
                        {% elif rec.priority_level == 'medium' %}<span class="badge bg-warning text-dark">Med</span>
                        {% else %}<span class="badge bg-secondary">Low</span>{% endif %}
                    </div>
                    <p class="small text-muted mb-0 mt-1">{{ rec.description|truncatechars:140 }}</p>
                </div>
                {% empty %}
                <p class="text-muted small mb-0">Run a scan to generate tailored recommendations.</p>
                {% endfor %}
                <a href="{% url 'exposure_scan' %}" class="btn btn-sm btn-outline-primary mt-2">Open exposure scan</a>
            </div>
        </div>
    </div>
</div>
{% else %}
<div class="alert alert-secondary border-0 small mb-4">
    <i class="bi bi-database-slash me-2"></i>
    Exposure monitoring tables are not installed. Deploy the schema from <code>privacyvault_schema.sql</code> (includes exposure tables) to enable this section.
</div>
{% endif %}

<div class="card content-card fade-up mb-4">
    <div class="card-header border-bottom-0 pt-4 pb-0">
        <h5 class="card-title fw-bold"><i class="bi bi-activity me-2 text-accent"></i> Recent Activity Log</h5>
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-hover align-middle">
                <thead class="table-dark">
                    <tr>
                        <th>Date</th>
                        <th>Action</th>
                        <th>Details</th>
                    </tr>
                </thead>
                <tbody>
                    {% for activity in recent_activities %}
                        <tr>
                            <td class="text-muted">{{ activity.created_at|date:"M d, Y" }}</td>
                            <td><span class="badge-soft">{{ activity.action_type }}</span></td>
                            <td class="small text-muted">{{ activity.description|default:"-" }}</td>
                        </tr>
                    {% empty %}
                        <tr>
                            <td colspan="3" class="text-center py-4 text-muted">No recent activity yet.</td>
                        </tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>
    </div>
</div>

<div class="row stagger">
    <div class="col-md-7">
        <div class="card content-card fade-up h-100">
            <div class="card-header border-bottom-0 pt-4 pb-0">
                <h5 class="card-title fw-bold"><i class="bi bi-clock-history me-2 text-warning"></i> Upcoming Expirations</h5>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead class="table-dark">
                            <tr>
                                <th>Company</th>
                                <th>Expiry Date</th>
                            </tr>
                        </thead>
                        <tbody>
                            {% for consent in upcoming_expirations %}
                                <tr>
                                    <td><strong>{{ consent.company.name }}</strong></td>
                                    <td><span class="text-warning">{{ consent.expiry_date|date:"M d, Y" }}</span></td>
                                </tr>
                            {% empty %}
                                <tr>
                                    <td colspan="2" class="text-center py-4 text-muted">No upcoming expirations.</td>
                                </tr>
                            {% endfor %}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-5">
        <div class="card content-card fade-up h-100">
            <div class="card-header border-bottom-0 pt-4 pb-0">
                <h5 class="card-title fw-bold"><i class="bi bi-bell me-2 text-info"></i> Latest Alerts</h5>
            </div>
            <div class="card-body">
                <div class="list-group list-group-flush">
                    {% for note in notifications %}
                        <div class="list-group-item bg-transparent text-light border-secondary px-0">
                            <div class="d-flex w-100 justify-content-between">
                                <h6 class="mb-1 fw-bold">{{ note.title }}</h6>
                                <small class="text-muted">{{ note.created_at|timesince }} ago</small>
                            </div>
                            <p class="mb-1 small text-muted">{{ note.message }}</p>
                        </div>
                    {% empty %}
                        <div class="text-center py-4 text-muted">No new notifications.</div>
                    {% endfor %}
                </div>
            </div>
        </div>
    </div>
</div>
{% endblock %}
