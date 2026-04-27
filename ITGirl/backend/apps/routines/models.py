import uuid
from django.conf import settings
from django.db import models


class Routine(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255)
    body = models.TextField(blank=True, default='')
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='routines')
    kind = models.CharField(max_length=64, blank=True, default='grwm')
    custom_kind_label = models.CharField(max_length=128, blank=True, default='')
    is_paywalled = models.BooleanField(default=False)
    unlock_price_cents = models.PositiveIntegerField(default=0)
    remote_cover_image_urls = models.JSONField(default=list, blank=True)
    steps = models.JSONField(default=list, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class RoutineEntitlement(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='routine_entitlements')
    routine = models.ForeignKey(Routine, on_delete=models.CASCADE, related_name='entitlements')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['user', 'routine'], name='uniq_entitlement_user_routine')
        ]
