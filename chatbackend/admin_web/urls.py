from django.urls import path
from . import views

urlpatterns = [
    path('login/', views.admin_login, name='admin_login'),
    path('dashboard/', views.dashboard, name='dashboard'),
    path('logout/', views.admin_logout, name='admin_logout'),
    path('users/', views.user_list, name='user_list'),
    path('users/edit/<int:user_id>/', views.edit_user, name='edit_user'),  # Edit user
    path('users/delete/<int:user_id>/', views.delete_user, name='delete_user'),  # Delete user
    path('users/disable/<int:user_id>/', views.disable_user, name='disable_user'),
    path('users/activate/<int:user_id>/', views.activate_user, name='activate_user'),
    path('users/roles/', views.roles_view, name='roles'),  # Roles page
    path('users/change_role/<int:user_id>/', views.change_role, name='change_role'),  # Change role action
]