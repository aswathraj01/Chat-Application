from django.urls import path
from .views import SignUpView, LoginView

urlpatterns = [
    path('signup/', SignUpView, name='signup'),
    path('login/', LoginView, name='login'),
]
