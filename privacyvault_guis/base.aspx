{% load static %}
<!DOCTYPE html>
<html lang="en" data-bs-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PrivacyVault - {% block title %}{% endblock %}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">
    <link rel="stylesheet" href="{% static 'css/app.css' %}">
    {% block extra_head %}{% endblock %}
</head>
<body>
    <div class="bg-animated">
        <div class="glow-orb orb-1"></div>
        <div class="glow-orb orb-2"></div>
    </div>
    
    {# Do not set z-index on this wrapper: it traps .modal below body-level .modal-backdrop (dim overlay, no clicks). #}
    <div class="container-fluid position-relative">
        <div class="row">
            <nav class="col-md-3 col-lg-2 d-md-block sidebar collapse">
                <div class="text-center mb-4">
                    <a href="{% url 'landing' %}" class="text-decoration-none text-light"><h4 class="brand-logo fw-bold mb-0">🛡️ PrivacyVault</h4></a>
                </div>
                <a href="{% url 'home' %}" class="{% if request.resolver_match.url_name == 'home' %}active{% endif %}">
                    <i class="bi bi-speedometer2 me-2"></i> Dashboard
                </a>
                <a href="{% url 'exposure_scan' %}" class="{% if request.resolver_match.url_name == 'exposure_scan' %}active{% endif %}">
                    <i class="bi bi-radar me-2"></i> Exposure Scan
                </a>
                <a href="{% url 'companies' %}" class="{% if request.resolver_match.url_name == 'companies' %}active{% endif %}">
                    <i class="bi bi-building me-2"></i> My Companies
                </a>
                <a href="{% url 'consents' %}" class="{% if request.resolver_match.url_name == 'consents' %}active{% endif %}">
                    <i class="bi bi-file-earmark-check me-2"></i> Consents
                </a>
                <a href="{% url 'requests' %}" class="{% if request.resolver_match.url_name == 'requests' %}active{% endif %}">
                    <i class="bi bi-trash me-2"></i> Deletion Requests
                </a>
                <a href="{% url 'profile' %}" class="{% if request.resolver_match.url_name == 'profile' %}active{% endif %}">
                    <i class="bi bi-person me-2"></i> Profile Settings
                </a>
                <a href="{% url 'notifications' %}" class="{% if request.resolver_match.url_name == 'notifications' %}active{% endif %}">
                    <i class="bi bi-bell me-2"></i> Alerts
                </a>
                <a href="{% url 'breach_history' %}" class="{% if request.resolver_match.url_name == 'breach_history' %}active{% endif %}">
                    <i class="bi bi-shield-exclamation me-2"></i> Breach History
                </a>
                <a href="{% url 'activity_log' %}" class="{% if request.resolver_match.url_name == 'activity_log' %}active{% endif %}">
                    <i class="bi bi-activity me-2"></i> Activity Log
                </a>
                <a href="{% url 'sessions' %}" class="{% if request.resolver_match.url_name == 'sessions' %}active{% endif %}">
                    <i class="bi bi-laptop me-2"></i> Sessions
                </a>
                <hr class="text-secondary mx-3">
                <a href="{% url 'admin_panel' %}" class="text-warning {% if request.resolver_match.url_name == 'admin_panel' %}active{% endif %}">
                    <i class="bi bi-shield-lock me-2"></i> Admin Panel
                </a>
                <a href="{% url 'logout' %}" class="text-danger mt-3">
                    <i class="bi bi-box-arrow-right me-2"></i> Logout
                </a>
            </nav>

            <main class="col-md-9 ms-sm-auto col-lg-10 px-md-4 py-4">
                {% if messages %}
                    <div class="stagger">
                        {% for message in messages %}
                            <div class="alert alert-{{ message.tags|default:'info' }} bg-opacity-10 border-0 rounded-3 mb-4 fade-up">
                                {{ message }}
                            </div>
                        {% endfor %}
                    </div>
                {% endif %}

                {% block content %}{% endblock %}
            </main>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            const observer = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if(entry.isIntersecting) {
                        entry.target.classList.add('visible');
                    } else {
                        entry.target.classList.remove('visible');
                    }
                });
            }, { threshold: 0.1 });
            
            document.querySelectorAll('.fade-up, .stagger').forEach(el => observer.observe(el));
        });
    </script>
    {% block extra_js %}{% endblock %}
</body>
</html>
