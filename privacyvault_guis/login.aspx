{% load static %}
<!DOCTYPE html>
<html lang="en" data-bs-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PrivacyVault - Login</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="{% static 'css/app.css' %}">

</head>
<body>
    <div class="bg-animated">
        <div class="glow-orb orb-1"></div>
        <div class="glow-orb orb-2"></div>
    </div>
    
    <a href="{% url 'landing' %}" class="text-decoration-none text-muted position-fixed" style="top: 24px; left: 24px; z-index: 100;">
        <i class="bi bi-arrow-left fs-3"></i>
    </a>
    
    <div class="container min-vh-100 d-flex align-items-center justify-content-center position-relative fade-up">
        <div class="auth-card w-100" style="max-width: 450px;">
            <div class="text-center mb-5">
                <a href="{% url 'landing' %}" class="text-decoration-none">
                    <h2 class="brand-logo fw-bold text-light" style="font-size: 2.5rem; letter-spacing:-1px;">
                        <span style="color:var(--accent);">Privacy</span>Vault
                    </h2>
                </a>
                <p class="text-muted">Welcome back. Secure your data.</p>
            </div>
            
            {% if messages %}
                {% for message in messages %}
                    <div class="alert alert-{{ message.tags|default:'info' }} bg-opacity-10 border-0 rounded-3 mb-4">{{ message }}</div>
                {% endfor %}
            {% endif %}
            
            {% if form.non_field_errors %}
                <div class="alert alert-danger bg-opacity-10 border-0 rounded-3 mb-4">
                    {{ form.non_field_errors }}
                </div>
            {% endif %}
            
            <form method="post" class="stagger">
                {% csrf_token %}
                
                <div class="form-floating mb-3">
                    {{ form.email }}
                    <label for="{{ form.email.id_for_label }}">Email Address</label>
                    {{ form.email.errors }}
                </div>
                
                <div class="form-floating mb-4">
                    {{ form.password }}
                    <label for="{{ form.password.id_for_label }}">Password</label>
                    {{ form.password.errors }}
                </div>
                
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div class="form-check">
                        <input class="form-check-input" type="checkbox" id="rememberMe">
                        <label class="form-check-label text-muted small" for="rememberMe">Remember me</label>
                    </div>
                    <a href="{% url 'password_reset' %}" class="small text-decoration-none" style="color:var(--accent);">Forgot password?</a>
                </div>
                
                <button type="submit" class="btn btn-accent w-100 py-3 rounded-3 fw-bold fs-5 shadow mb-4">Sign In</button>
                
                <div class="text-center">
                    <p class="text-muted mb-0">
                        Don't have an account? <a href="{% url 'signup' %}" class="text-decoration-none" style="color:var(--accent); font-weight:600;">Sign up</a>
                    </p>
                </div>
            </form>
        </div>
    </div>
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
</body>
</html>
