from django.urls import path, include

urlpatterns = [
    path('api/', include('chat.urls')),  # Include chat app URLs
]