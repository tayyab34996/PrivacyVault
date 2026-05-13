{% load static %}
<!DOCTYPE html>
<html lang="en" data-bs-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PrivacyVault - Set New Password</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="{% static 'css/app.css' %}">
</head>
<body>
    <div class="app-blur blur-1"></div>
    <div class="app-blur blur-2"></div>
    <div class="container py-5 position-relative" style="z-index: 1;">
        <div class="row justify-content-center">
            <div class="col-md-5">
                <div class="card content-card fade-up p-4">
                    <h4>Set New Password</h4>
                    <form method="post">
                        {% csrf_token %}
                        {% for field in form %}
                            <div class="form-floating mb-3">
                                {{ field }}
                                <label for="{{ field.id_for_label }}">{{ field.label }}</label>
                                {% if field.errors %}
                                    <div class="text-danger small mt-1">{{ field.errors|join:", " }}</div>
                                {% endif %}
                            </div>
                        {% endfor %}
                        <button class="btn btn-accent w-100" type="submit">Update Password</button>
                    </form>
                </div>
            </div>
        </div>
    </div>
    <script>
        document.querySelectorAll('.fade-up, .stagger').forEach((el) => el.classList.add('visible'));
        document.querySelectorAll('input[type="password"]').forEach(el => el.classList.add('form-control'));
    </script>
</body>
</html>
