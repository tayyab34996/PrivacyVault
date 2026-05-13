{% load static %}
<!DOCTYPE html>
<html lang="en" data-bs-theme="dark">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PrivacyVault - Take Back Your Data</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">
    <link rel="stylesheet" href="{% static 'css/app.css' %}">
</head>

<body data-bs-spy="scroll" data-bs-target="#landingNav" data-bs-smooth-scroll="true" tabindex="0" style="padding-top: 70px;">
    <div class="bg-animated">
        <div class="glow-orb orb-1"></div>
        <div class="glow-orb orb-2"></div>
    </div>

    <nav class="landing-nav fixed-top" style="background: rgba(9, 9, 11, 0.85); backdrop-filter: blur(12px); border-bottom: 1px solid rgba(255,255,255,0.05);">
        <div class="container py-3 d-flex align-items-center justify-content-between">
            <div class="d-flex align-items-center gap-2">
                <a href="{% url 'landing' %}" class="text-decoration-none text-light d-flex align-items-center gap-2">
                    <span class="fs-4">🛡️</span>
                    <strong class="fs-5">PrivacyVault</strong>
                </a>
            </div>
            <ul class="nav gap-3" id="landingNav">
                <li class="nav-item"><a class="nav-link" href="#overview">Overview</a></li>
                <li class="nav-item"><a class="nav-link" href="#features">Features</a></li>
                <li class="nav-item"><a class="nav-link" href="#risk">Risk Score</a></li>
                <li class="nav-item"><a class="nav-link" href="#workflow">Workflow</a></li>
                <li class="nav-item"><a class="nav-link" href="#faq">FAQ</a></li>
            </ul>
            <div class="d-flex gap-2">
                <a class="btn btn-outline-light" href="{% url 'login' %}">Login</a>
                <a class="btn btn-accent" href="{% url 'signup' %}">Get Started</a>
            </div>
        </div>
    </nav>

    <header id="overview" class="landing-hero">
        <div class="container position-relative" style="z-index: 1;">
            <div class="row align-items-center">
                <div class="col-lg-6 fade-up">
                    <div class="landing-tag mb-3"><i class="bi bi-shield-check"></i> Know who has your data</div>
                    <h1 class="landing-title">See every company holding your data. Manage consent in one place.</h1>
                    <p class="text-muted mt-3">PrivacyVault turns your scattered digital footprint into a clean, actionable dashboard. Track who has your information, when consent expires, and what to do next.</p>
                    <div class="d-flex gap-3 mt-4">
                        <a class="btn btn-accent btn-lg" href="{% url 'signup' %}">Get Started</a>
                        <a class="btn btn-outline-light btn-lg" href="{% url 'login' %}">Login</a>
                    </div>
                    <div class="d-flex gap-3 mt-4">
                        <a href="#features" class="pill">Consent tracking</a>
                        <a href="#risk" class="pill">Breach alerts</a>
                        <a href="#risk" class="pill">Privacy score</a>
                    </div>
                </div>
                <div class="col-lg-6 mt-4 mt-lg-0">
                    <div class="glass-panel p-4 fade-up">
                        <div class="d-flex justify-content-between align-items-center">
                            <div>
                                <p class="text-muted mb-1">Privacy Risk Score</p>
                                <h2 class="risk-score">72<span class="fs-6 text-muted">/100</span></h2>
                            </div>
                            <span class="badge bg-danger">High Exposure</span>
                        </div>
                        <div class="mt-4">
                            <div class="d-flex justify-content-between mb-2">
                                <span class="text-muted">Active Consents</span>
                                <strong>18</strong>
                            </div>
                            <div class="progress" style="height: 8px;">
                                <div class="progress-bar bg-info" role="progressbar" style="width: 65%"></div>
                            </div>
                        </div>
                        <div class="mt-4">
                            <div class="d-flex justify-content-between mb-2">
                                <span class="text-muted">Upcoming Expirations</span>
                                <strong>4</strong>
                            </div>
                            <div class="progress" style="height: 8px;">
                                <div class="progress-bar bg-warning" role="progressbar" style="width: 40%"></div>
                            </div>
                        </div>
                        <div class="mt-4">
                            <div class="d-flex justify-content-between mb-2">
                                <span class="text-muted">Deletion Requests</span>
                                <strong>2</strong>
                            </div>
                            <div class="progress" style="height: 8px;">
                                <div class="progress-bar bg-success" role="progressbar" style="width: 20%"></div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </header>

    <section id="features" class="py-5">
        <div class="container">
            <div class="d-flex justify-content-between align-items-end mb-4">
                <div>
                    <p class="text-muted mb-1">What you can do</p>
                    <h2 class="section-title">Build a privacy command center</h2>
                </div>
                <span class="landing-tag"><i class="bi bi-lightning-charge"></i> Live insights</span>
            </div>
            <div class="row g-4 stagger">
                <div class="col-md-4">
                    <div class="feature-card p-4 h-100 fade-up">
                        <i class="bi bi-building fs-2 text-info"></i>
                        <h5 class="mt-3">Company Inventory</h5>
                        <p class="text-muted">Track every company holding your data with clear categories, ratings, and breach flags.</p>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="feature-card p-4 h-100 fade-up">
                        <i class="bi bi-file-earmark-check fs-2 text-warning"></i>
                        <h5 class="mt-3">Consent Timeline</h5>
                        <p class="text-muted">Record consent duration, set expirations, and filter active vs expired records fast.</p>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="feature-card p-4 h-100 fade-up">
                        <i class="bi bi-trash fs-2 text-danger"></i>
                        <h5 class="mt-3">Deletion Requests</h5>
                        <p class="text-muted">Log deletion requests, track status changes, and document responses.</p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <section id="risk" class="py-5">
        <div class="container">
            <div class="row align-items-center">
                <div class="col-lg-6">
                    <div class="glass-panel p-4 fade-up">
                        <h3 class="section-title">Privacy Risk Score</h3>
                        <p class="text-muted">Your score blends company count, data sensitivity, and company ratings. The higher the score, the higher the exposure.</p>
                        <ul class="list-unstyled mt-4">
                            <li class="mb-2"><i class="bi bi-check-circle text-success"></i> Sensitive data weighs more</li>
                            <li class="mb-2"><i class="bi bi-check-circle text-success"></i> Low-rated companies increase risk</li>
                            <li class="mb-2"><i class="bi bi-check-circle text-success"></i> Fewer companies = lower exposure</li>
                        </ul>
                    </div>
                </div>
                <div class="col-lg-6 mt-4 mt-lg-0">
                    <div class="feature-card fade-up">
                        <h4>Why it matters</h4>
                        <p class="text-muted">Knowing your risk helps you decide when to revoke consent, request deletion, or avoid risky services.</p>
                        <div class="d-flex gap-3 mt-4">
                            <div class="text-center">
                                <h3 class="text-warning">+42%</h3>
                                <p class="small text-muted">faster response to data leaks</p>
                            </div>
                            <div class="text-center">
                                <h3 class="text-info">-30%</h3>
                                <p class="small text-muted">reduced exposure</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <section id="workflow" class="py-5">
        <div class="container">
            <h2 class="section-title mb-4">How it works</h2>
            <div class="row g-4">
                <div class="col-md-4">
                    <div class="feature-card p-4 h-100 fade-up">
                        <h5>1. Add companies</h5>
                        <p class="text-muted">Log every platform where you shared personal data.</p>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="feature-card p-4 h-100 fade-up">
                        <h5>2. Record consent</h5>
                        <p class="text-muted">Attach data categories and expiry dates.</p>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="feature-card p-4 h-100 fade-up">
                        <h5>3. Act on insights</h5>
                        <p class="text-muted">Send deletion requests or update consent before expiry.</p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <section id="faq" class="py-5">
        <div class="container">
            <h2 class="section-title mb-4">FAQ</h2>
            <div class="row g-4">
                <div class="col-md-6">
                    <div class="feature-card p-4 h-100 fade-up">
                        <h6>Does PrivacyVault store my data?</h6>
                        <p class="text-muted">Only the information you intentionally add. You can delete it anytime.</p>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="feature-card p-4 h-100 fade-up">
                        <h6>Can I export my records?</h6>
                        <p class="text-muted">Yes. We can add CSV/PDF exports in the next iteration.</p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <footer class="py-4 text-center text-muted">
        <div class="container">
            <p>PrivacyVault &copy; 2026. Control your digital footprint.</p>
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            // Smooth scrolling for anchor links
            document.querySelectorAll('a[href^="#"]').forEach(anchor => {
                anchor.addEventListener('click', function (e) {
                    e.preventDefault();
                    const targetId = this.getAttribute('href');
                    const targetElement = document.querySelector(targetId);
                    if (targetElement) {
                        const offset = 80; // Adjust for sticky header
                        const elementPosition = targetElement.getBoundingClientRect().top;
                        const offsetPosition = elementPosition + window.pageYOffset - offset;

                        window.scrollTo({
                            top: offsetPosition,
                            behavior: 'smooth'
                        });
                    }
                });
            });

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
