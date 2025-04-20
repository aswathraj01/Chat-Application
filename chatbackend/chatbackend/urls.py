from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import TokenRefreshView
from users.views import RegisterView, UserInfoView, CustomLoginView
from chat.views import ChatHistoryView
from users.views import update_user
from support.views import create_support_request  
from admin_web import views



urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/login/', CustomLoginView.as_view(), name='custom_token_obtain'),  # Use custom view
    path('api/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/signup/', RegisterView.as_view(), name='signup'),
    path('api/userinfo/', UserInfoView.as_view(), name='user_info'),
    path('api/user/update/', update_user, name='update_user'),
    path('api/chat/history/', ChatHistoryView.as_view(), name='chat-history'),
    path('web/', include('web_interface.urls')),
    path('admin_web/', include('admin_web.urls')),
    path('api/support/', create_support_request, name='support_request'),
    path('settings/', views.admin_settings_view, name='admin_settings'),
    path('support/', views.support_list, name='support_list'),
    path('support/toggle_fixed/<int:ticket_id>/', views.toggle_fixed, name='toggle_fixed'),
    path('support/toggle_important/<int:ticket_id>/', views.toggle_important, name='toggle_important'),
    path('support/respond/<int:ticket_id>/', views.respond_to_ticket, name='respond_to_ticket'),
]
