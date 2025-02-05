from django.urls import path
from .views import UserListCreateView, UserDetailView, ChatHistoryListView, UserSettingsView

urlpatterns = [
    # User endpoints
    path('users/', UserListCreateView.as_view(), name='user-list-create'),
    path('users/<int:pk>/', UserDetailView.as_view(), name='user-detail'),

    # Chat history endpoints
    path('chat-history/', ChatHistoryListView.as_view(), name='chat-history-list'),

    # User settings endpoints
    path('user-settings/', UserSettingsView.as_view(), name='user-settings'),
]