# PrivacyVault

PrivacyVault is a sophisticated privacy management platform designed to help users track, manage, and control their personal data footprint across various companies and services.

## 🚀 Features

- **Company Inventory**: Track every company holding your personal data with clear categories and risk ratings.
- **Consent Management**: Monitor active and expired consents with an interactive timeline.
- **Privacy Risk Score**: Dynamic calculation of your data exposure based on company ratings and data sensitivity.
- **Breach Monitoring**: Get notified about data breaches from companies you've shared data with.
- **Deletion Requests**: Log and track the status of your data deletion requests.
- **Activity Logging**: Comprehensive tracking of all privacy-related actions.

## 🛠️ Technology Stack

- **Backend**: Django (Python)
- **Database**: SQL Server (Core logic implemented via Stored Procedures, Views, and Triggers)
- **Frontend**: Bootstrap 5 + ASPX-style templates with custom CSS
- **Authentication**: Secure built-in Django authentication system

## 📋 Database Architecture

This project emphasizes robust database design:
- **Stored Procedures**: All CRUD operations and complex logic (like registration and risk calculation) are handled through optimized SPs.
- **Views**: Used for high-performance dashboard metrics and aggregated data.
- **Triggers**: Automated activity logging on data modifications to ensure audit integrity.
- **Transactions**: Ensuring data consistency during complex multi-step operations.

## 🚦 Getting Started

### Prerequisites
- Python 3.8+
- SQL Server (or compatible backend)
- Virtual Environment (recommended)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/PrivacyVault.git
   cd PrivacyVault
   ```

2. **Set up virtual environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure Database**:
   - Update `DATABASES` settings in `PrivacyVault/settings.py` to point to your SQL Server instance.
   - Run the provided `privacyvault_schema.sql` script in your SQL Server Management Studio to initialize the schema, stored procedures, and triggers.

5. **Run Migrations**:
   ```bash
   python manage.py migrate
   ```

6. **Start the server**:
   ```bash
   python manage.py runserver
   ```

## 🔒 Security

PrivacyVault is built with "Privacy by Design" principles. We only store information you explicitly add to your vault to help you manage your digital footprint.

## 📝 License

This project was developed for educational purposes as part of a University Project focusing on fundamental database concepts and web development.
