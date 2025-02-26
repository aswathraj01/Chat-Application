from rest_framework.permissions import BasePermission

class IsSuperadmin(BasePermission):
    def has_permission(self, request, view):
        return request.user.role == 'SUPERADMIN'