from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    display_name = models.CharField(max_length=120, blank=True, default='')
    profile_picture_url = models.URLField(blank=True, default='')

    @property
    def resolved_display_name(self) -> str:
        return self.display_name or self.username
