from django.contrib import admin
from .models import UserProfile

class UserProfileAdmin(admin.ModelAdmin):
    # Exclude non-existent fields like 'groups' and 'user_permissions'
    filter_horizontal = ['groups', 'user_permissions']
    list_filter = ['is_active', 'is_staff']  # Adjust based on fields in your model
    list_display = ['username', 'email', 'first_name', 'last_name', 'is_active', 'is_staff', 'date_joined']

    # You may also want to add search functionality
    search_fields = ['username', 'email', 'first_name', 'last_name']

admin.site.register(UserProfile, UserProfileAdmin)
