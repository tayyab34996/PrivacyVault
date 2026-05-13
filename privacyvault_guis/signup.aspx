{% load static %}
<!DOCTYPE html>
<html lang="en" data-bs-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PrivacyVault - Sign Up</title>
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
        <div class="auth-card w-100" style="max-width: 500px;">
            <div class="text-center mb-5">
                <a href="{% url 'landing' %}" class="text-decoration-none">
                    <h2 class="brand-logo fw-bold text-light" style="font-size: 2.5rem; letter-spacing:-1px;">
                        <span style="color:var(--accent);">Privacy</span>Vault
                    </h2>
                </a>
                <p class="text-muted">Take control of your digital footprint.</p>
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
                <div class="row g-3 mb-3">
                    <div class="col-md-6">
                        <div class="form-floating">
                            {{ form.name }}
                            <label for="{{ form.name.id_for_label }}">Full Name</label>
                            {{ form.name.errors }}
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="form-floating">
                            {{ form.phone_number }}
                            <label for="{{ form.phone_number.id_for_label }}">Phone</label>
                            {{ form.phone_number.errors }}
                        </div>
                    </div>
                </div>
                
                <div class="form-floating mb-3">
                    {{ form.email }}
                    <label for="{{ form.email.id_for_label }}">Email Address (Gmail Required)</label>
                    {{ form.email.errors }}
                </div>
                
                <div class="form-floating mb-3">
                    {{ form.password1 }}
                    <label for="{{ form.password1.id_for_label }}">Password</label>
                    {{ form.password1.errors }}
                    <div class="mt-2 small text-muted" id="passwordStrength">Strength: -</div>
                </div>
                
                <div class="form-floating mb-4">
                    {{ form.password2 }}
                    <label for="{{ form.password2.id_for_label }}">Confirm Password</label>
                    {{ form.password2.errors }}
                </div>
                
                <button type="submit" class="btn btn-accent w-100 py-3 rounded-3 fw-bold fs-5 shadow">Create Account</button>
                
                <p class="text-center mt-4 mb-0 text-muted">
                    Already have an account? <a href="{% url 'login' %}" class="text-decoration-none" style="color:var(--accent); font-weight:600;">Sign in</a>
                </p>
            </form>
        </div>
    </div>
    
    <script>
        const pwdInput = document.getElementById("{{ form.password1.id_for_label }}");
        const strengthText = document.getElementById("passwordStrength");
        if (pwdInput) {
            pwdInput.addEventListener("input", (e) => {
                const val = e.target.value;
                let score = 0;
                if (val.length >= 8) score++;
                if (/[A-Z]/.test(val)) score++;
                if (/[0-9]/.test(val)) score++;
                if (/[^A-Za-z0-9]/.test(val)) score++;
                
                if (!val) { strengthText.textContent = "Strength: -"; strengthText.style.color = "inherit"; }
                else if (score <= 1) { strengthText.textContent = "Strength: Weak"; strengthText.style.color = "var(--danger)"; }
                else if (score === 2) { strengthText.textContent = "Strength: Fair"; strengthText.style.color = "var(--warning)"; }
                else { strengthText.textContent = "Strength: Strong"; strengthText.style.color = "var(--success)"; }
            });
        }

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
