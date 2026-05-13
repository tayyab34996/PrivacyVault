{% load static %}
<!DOCTYPE html>
<html lang="en" data-bs-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PrivacyVault - Reset Password</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="{% static 'css/app.css' %}">
</head>
<body>
    <div class="app-blur blur-1"></div>
    <div class="app-blur blur-2"></div>
    <div class="container py-5 position-relative" style="z-index: 1;">
        <div class="row justify-content-center">
            <div class="col-md-5">
                <div class="card content-card fade-up">
                    <div class="login-header" style="background: linear-gradient(135deg, #1e293b, #0f172a);">
                        <h3>Reset Password</h3>
                        <p class="mb-0 text-light">We'll send a reset link to your email.</p>
                    </div>
                    <div class="login-body" style="background: #0f141f;">
                        <form method="post">
                            {% csrf_token %}
                            <label for="id_email" class="form-label text-muted">Email</label>
                            <input type="email" name="email" class="form-control" id="id_email" required>
                            {% if form.email.errors %}
                                <div class="text-danger small mt-1">{{ form.email.errors }}</div>
                            {% endif %}
                            <div class="d-grid mt-3">
                                <button class="btn btn-accent" type="submit">Send Reset Link</button>
                            </div>
                        </form>
                        <div class="text-center mt-3">
                            <a class="text-decoration-none text-primary" href="{% url 'login' %}">Back to login</a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <script>
        document.querySelectorAll('.fade-up, .stagger').forEach((el) => el.classList.add('visible'));
    </script>
</body>
</html>
