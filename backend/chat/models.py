from django.contrib.auth.models import AbstractUser, Group, Permission
from django.db import models
from django.conf import settings

# Custom User model (replace auth.User)
class User(AbstractUser):
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)

    # Fix reverse accessor clash for groups and permissions
    groups = models.ManyToManyField(
        Group,
        related_name="chat_user_groups",  # Unique related_name
        blank=True,
        help_text="The groups this user belongs to.",
        verbose_name="groups",
    )
    user_permissions = models.ManyToManyField(
        Permission,
        related_name="chat_user_permissions",  # Unique related_name
        blank=True,
        help_text="Specific permissions for this user.",
        verbose_name="user permissions",
    )

    def __str__(self):
        return self.username

# Chat history model
class ChatHistory(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,  # Use the custom User model
        on_delete=models.CASCADE,
        related_name='chat_history'
    )
    role = models.CharField(max_length=20)  # 'system' or 'user'
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.role}: {self.content}"

# User settings model
class UserSettings(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,  # Use the custom User model
        on_delete=models.CASCADE,
        related_name='settings'
    )
    font_size = models.IntegerField(default=16)

    def __str__(self):
        return f"{self.user.username} - Font Size: {self.font_size}"