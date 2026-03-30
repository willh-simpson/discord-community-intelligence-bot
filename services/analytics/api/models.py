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