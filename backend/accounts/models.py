from django.db import models
from django.contrib.auth.models import BaseUserManager, AbstractBaseUser, PermissionsMixin
from django.utils import timezone


class UserProfileManager(BaseUserManager):
    def create_user(self, username, first_name, last_name, email, password=None):
        """Create and return a regular user with an email and password."""
        if not email:
            raise ValueError("The Email field must be set")
        email = self.normalize_email(email)
        user = self.model(username=username, first_name=first_name, last_name=last_name, email=email)
        user.set_password(password)  # Password is securely hashed
        user.save(using=self._db)
        return user

    def create_superuser(self, username, first_name, last_name, email, password=None):
        """Create and return a superuser with an email and password."""
        user = self.create_user(username, first_name, last_name, email, password)
        user.is_staff = True
        user.is_superuser = True
        user.save(using=self._db)
        return user


class UserProfile(AbstractBaseUser, PermissionsMixin):  # Inherit PermissionsMixin
    username = models.CharField(max_length=150, unique=True)
    first_name = models.CharField(max_length=30)
    last_name = models.CharField(max_length=30)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=255)  # Store hashed passwords securely
    is_active = models.BooleanField(default=True)  # Account active status
    is_staff = models.BooleanField(default=False)  # For admin control
    date_joined = models.DateTimeField(default=timezone.now)  # Timestamp of user creation

    # Required fields for AbstractBaseUser
    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = ['email', 'first_name', 'last_name']

    objects = UserProfileManager()

    def __str__(self):
        return self.username
