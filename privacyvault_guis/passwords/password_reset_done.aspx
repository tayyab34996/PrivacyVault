{% load static %}
<!DOCTYPE html>
<html lang="en" data-bs-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PrivacyVault - Email Sent</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="{% static 'css/app.css' %}">
</head>
<body>
    <div class="app-blur blur-1"></div>
    <div class="app-blur blur-2"></div>
    <div class="container py-5 position-relative" style="z-index: 1;">
        <div class="row justify-content-center">
            <div class="col-md-5">
                <div class="card content-card fade-up p-4 text-center">
                    <h4>Check your email</h4>
                    <p class="text-muted">We sent a password reset link if the email exists.</p>
                    <a class="btn btn-outline-light" href="{% url 'login' %}">Back to login</a>
                </div>
            </div>
        </div>
    </div>
    <script>
        document.querySelectorAll('.fade-up, .stagger').forEach((el) => el.classList.add('visible'));
    </script>
</body>
</html>
