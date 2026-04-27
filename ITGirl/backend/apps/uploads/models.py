from django.conf import settings
from django.db import models


class UploadedProfileImage(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='uploaded_profile_images')
    image = models.ImageField(upload_to='profile-photos/%Y/%m/%d')
    created_at = models.DateTimeField(auto_now_add=True)
