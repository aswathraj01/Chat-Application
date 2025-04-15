from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from users.views import RegisterView, UserInfoView
from chat.views import ChatHistoryView
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/login/', TokenObtainPairView.as_view(), name='token_obtain'),
    path('api/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/signup/', RegisterView.as_view(), name='signup'),
    path('api/userinfo/', UserInfoView.as_view(), name='user_info'),
    path('api/chat/history/', ChatHistoryView.as_view(), name='chat-history'),
    path('web/', include('web_interface.urls')),
    path('admin/', admin.site.urls),
    path('admin_web/', include('admin_web.urls')),
    
]