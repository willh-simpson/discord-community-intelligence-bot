from django.db import models

class MessageEvent(models.Model):
    user_id = models.CharField(max_length=128)
    channel_id = models.CharField(max_length=128)

    content_length = models.IntegerField()

    timestamp = models.DateTimeField()

    class Meta:
        indexes = [
            models.Index(fields=["timestamp"]),
            models.Index(fields=["channel_id"]),
            models.Index(fields=["user_id"]),
        ]


class SafetyAlert(models.Model):
    ALERT_TYPES = [
        ("spam", "Spam"),
        ("burst", "Burst"),
        ("raid", "Raid"),
        ("suspicious_join", "Suspicious Join"),
    ]

    alert_type = models.CharField(max_length=32, choices=ALERT_TYPES)
    channel_id = models.CharField(max_length=64, null=True, blank=True)
    guild_id = models.CharField(max_length=64, null=True, blank=True)

    count = models.IntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)