{% extends "base.aspx" %}
{% load static %}

{% block title %}Exposure Scan{% endblock %}

{% block content %}
<div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-4 border-bottom">
    <div>
        <h1 class="h2 brand-logo mb-1">Digital Exposure Scan</h1>
        <p class="text-muted small mb-0">
            Known exposure monitoring: we compare your inputs with <strong>breach records already stored</strong> in PrivacyVault.
            This is <strong>not</strong> live dark-web scanning or illegal-activity detection.
        </p>
    </div>
</div>

{% if not db_ready %}
<div class="alert alert-warning border-0 rounded-3 bg-opacity-10">
    <i class="bi bi-database-exclamation me-2"></i>
    Database tables for exposure scans are missing. Recreate or update the database using <code>privacyvault_schema.sql</code>, then refresh this page.
</div>
{% else %}
<div class="alert alert-info border-0 rounded-3 bg-opacity-10 small">
    <i class="bi bi-info-circle me-2"></i>
    Results are educational and based on your administrator’s breach catalog. Empty results do not prove you were never exposed elsewhere.
</div>
{% endif %}

<div class="row g-4 mb-4">
    <div class="col-lg-5">
        <div class="card content-card h-100">
            <div class="card-header border-secondary">
                <h5 class="card-title fw-bold mb-0"><i class="bi bi-radar me-2 text-accent"></i> Run a scan</h5>
            </div>
            <div class="card-body">
                {% if db_ready %}
                <form method="post" novalidate>
                    {% csrf_token %}
                    <div class="mb-3">
                        <label class="form-label">Email <span class="text-danger">*</span></label>
                        {{ form.email }}
                        {% if form.email.errors %}<div class="text-danger small">{{ form.email.errors }}</div>{% endif %}
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Phone <span class="text-muted">(optional)</span></label>
                        {{ form.phone }}
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Usernames <span class="text-muted">(optional)</span></label>
                        {{ form.usernames }}
                        {% if form.usernames.help_text %}<div class="form-text">{{ form.usernames.help_text }}</div>{% endif %}
                    </div>
                    <button type="submit" class="btn btn-primary w-100">
                        <i class="bi bi-shield-check me-1"></i> Start exposure scan
                    </button>
                </form>
                {% endif %}
            </div>
        </div>
    </div>
    <div class="col-lg-7">
        <div class="card content-card h-100">
            <div class="card-header border-secondary d-flex justify-content-between align-items-center">
                <h5 class="card-title fw-bold mb-0"><i class="bi bi-clock-history me-2 text-warning"></i> Recent scans</h5>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-dark">
                            <tr>
                                <th>Date</th>
                                <th>Email checked</th>
                                <th class="text-center">Score</th>
                                <th>Status</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            {% for s in recent_scans %}
                            <tr class="{% if viewing_scan and viewing_scan.scan_id == s.scan_id %}table-active{% endif %}">
                                <td class="text-muted small">{{ s.scan_date|date:"M d, Y H:i" }}</td>
                                <td>{{ s.email_checked|truncatechars:36 }}</td>
                                <td class="text-center">
                                    <span class="badge {% if s.risk_score > 70 %}bg-danger{% elif s.risk_score > 30 %}bg-warning text-dark{% else %}bg-success{% endif %}">{{ s.risk_score }}</span>
                                </td>
                                <td><span class="badge bg-secondary bg-opacity-25">{{ s.scan_status }}</span></td>
                                <td>
                                    <a class="btn btn-sm btn-outline-light" href="{% url 'exposure_scan' %}?scan_id={{ s.scan_id }}">View</a>
                                </td>
                            </tr>
                            {% empty %}
                            <tr>
                                <td colspan="5" class="text-center py-4 text-muted">No scans yet. Submit the form to create your first record.</td>
                            </tr>
                            {% endfor %}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

{% if viewing_scan and exposure_band %}
<div class="row g-4 mb-4">
    <div class="col-md-4">
        <div class="card stat-card text-center p-4 h-100 {% if exposure_band.0 == 'high' %}border-danger border-2{% elif exposure_band.0 == 'medium' %}border-warning border-2{% else %}border-success border-2{% endif %}">
            <h6 class="text-muted text-uppercase mb-2 small fw-bold">Exposure risk score</h6>
            <div class="risk-score">{{ viewing_scan.risk_score }}<span class="fs-6 text-muted">/100</span></div>
            <p class="mb-0 mt-2">
                {% if exposure_band.0 == 'high' %}
                <span class="badge bg-danger">High — {{ exposure_band.1 }}</span>
                {% elif exposure_band.0 == 'medium' %}
                <span class="badge bg-warning text-dark">Medium — {{ exposure_band.1 }}</span>
                {% else %}
                <span class="badge bg-success">Low — {{ exposure_band.1 }}</span>
                {% endif %}
            </p>
            <p class="small text-muted mt-3 mb-0">Bands: 0–30 low, 31–70 medium, 71+ high (from this scan’s matches).</p>
        </div>
    </div>
    <div class="col-md-8">
        <div class="card content-card h-100">
            <div class="card-header border-secondary">
                <h5 class="card-title fw-bold mb-0"><i class="bi bi-lightbulb me-2 text-info"></i> Recommended actions</h5>
            </div>
            <div class="card-body">
                <div class="list-group list-group-flush">
                    {% for r in recommendations %}
                    <div class="list-group-item bg-transparent text-light border-secondary px-0">
                        <div class="d-flex w-100 justify-content-between align-items-start gap-2">
                            <h6 class="mb-1 fw-bold">{{ r.title }}</h6>
                            {% if r.priority_level == 'high' %}
                            <span class="badge bg-danger flex-shrink-0">High</span>
                            {% elif r.priority_level == 'medium' %}
                            <span class="badge bg-warning text-dark flex-shrink-0">Medium</span>
                            {% else %}
                            <span class="badge bg-secondary flex-shrink-0">Low</span>
                            {% endif %}
                        </div>
                        <p class="mb-0 small text-muted">{{ r.description }}</p>
                    </div>
                    {% empty %}
                    <div class="text-muted">No recommendations stored for this scan.</div>
                    {% endfor %}
                </div>
            </div>
        </div>
    </div>
</div>

<div class="card content-card mb-4">
    <div class="card-header border-secondary">
        <h5 class="card-title fw-bold mb-0"><i class="bi bi-bug me-2 text-danger"></i> Detected breach matches (this scan)</h5>
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-hover align-middle">
                <thead class="table-dark">
                    <tr>
                        <th>Company</th>
                        <th>Breach date</th>
                        <th>Severity</th>
                        <th>Data types (inferred)</th>
                        <th>Details</th>
                    </tr>
                </thead>
                <tbody>
                    {% for m in breach_matches %}
                    <tr>
                        <td><strong>{{ m.breach.company.name }}</strong></td>
                        <td>{{ m.breach.breach_date|date:"M d, Y" }}</td>
                        <td>
                            {% if m.breach.severity == 'high' %}
                            <span class="badge bg-danger">High</span>
                            {% elif m.breach.severity == 'medium' %}
                            <span class="badge bg-warning text-dark">Medium</span>
                            {% else %}
                            <span class="badge bg-secondary">Low</span>
                            {% endif %}
                        </td>
                        <td class="small text-muted">{{ m.data_exposed }}</td>
                        <td class="small">{{ m.description|truncatechars:180 }}</td>
                    </tr>
                    {% empty %}
                    <tr>
                        <td colspan="5" class="text-center py-4 text-muted">
                            No breach rows matched your profile against our on-file catalog for this scan.
                        </td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>
    </div>
</div>
{% endif %}
{% endblock %}
