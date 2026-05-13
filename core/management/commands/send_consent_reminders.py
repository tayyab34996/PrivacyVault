from datetime import timedelta

from django.core.management.base import BaseCommand
from django.core.mail import send_mail
from django.utils import timezone

from core.models import ConsentRecord, Notification
from django.conf import settings


class Command(BaseCommand):
    help = 'Send reminders for consents expiring soon.'

    def handle(self, *args, **options):
        today = timezone.now().date()
        upcoming = ConsentRecord.objects.filter(
            expiry_date__isnull=False,
            expiry_date__range=(today, today + timedelta(days=7)),
        ).select_related('company', 'user')

        for consent in upcoming:
            Notification.objects.create(
                user=consent.user,
                title='Consent Expiring Soon',
                message=f"Consent for {consent.company.name} expires on {consent.expiry_date}.",
                link='/consents/',
            )
            send_mail(
                'PrivacyVault Consent Reminder',
                f"Your consent for {consent.company.name} expires on {consent.expiry_date}.",
                settings.DEFAULT_FROM_EMAIL,
                [consent.user.email],
                fail_silently=True,
            )

        self.stdout.write(self.style.SUCCESS('Consent reminders processed.'))
