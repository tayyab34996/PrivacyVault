# Exposure monitoring ORM state (tables defined in privacyvault_schema.sql; managed=False).

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0002_sync_orm_state'),
    ]

    operations = [
        migrations.CreateModel(
            name='ExposureScan',
            fields=[
                ('scan_id', models.AutoField(primary_key=True, serialize=False)),
                ('email_checked', models.CharField(max_length=255)),
                ('phone_checked', models.CharField(blank=True, max_length=30, null=True)),
                ('usernames_checked', models.CharField(blank=True, max_length=500, null=True)),
                ('scan_date', models.DateTimeField()),
                ('risk_score', models.IntegerField(default=0)),
                ('scan_status', models.CharField(default='completed', max_length=20)),
                (
                    'user',
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name='exposure_scans',
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={
                'db_table': 'exposure_scans',
                'ordering': ['-scan_date'],
                'managed': False,
            },
        ),
        migrations.CreateModel(
            name='BreachMatch',
            fields=[
                ('match_id', models.AutoField(primary_key=True, serialize=False)),
                ('data_exposed', models.CharField(max_length=500)),
                ('description', models.CharField(max_length=1000)),
                (
                    'breach',
                    models.ForeignKey(
                        db_column='breach_id',
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name='exposure_matches',
                        to='core.breachrecord',
                    ),
                ),
                (
                    'scan',
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name='breach_matches',
                        to='core.exposurescan',
                    ),
                ),
            ],
            options={
                'db_table': 'breach_matches',
                'managed': False,
                'unique_together': {('scan', 'breach')},
            },
        ),
        migrations.CreateModel(
            name='ExposureRecommendation',
            fields=[
                ('recommendation_id', models.AutoField(primary_key=True, serialize=False)),
                ('title', models.CharField(max_length=200)),
                ('description', models.CharField(max_length=1000)),
                ('priority_level', models.CharField(default='medium', max_length=20)),
                (
                    'scan',
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name='recommendations',
                        to='core.exposurescan',
                    ),
                ),
            ],
            options={
                'db_table': 'recommendations',
                'managed': False,
            },
        ),
    ]
