from django.db import models
from django.contrib.auth import get_user_model

class SupportRequest(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField()
    message = models.TextField()
    is_fixed = models.BooleanField(default=False)
    is_important = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    response = models.TextField(blank=True, null=True)
    
    def __str__(self):
        return f"Support Request from {self.name}"
