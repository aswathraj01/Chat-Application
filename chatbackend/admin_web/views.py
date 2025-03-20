from django.contrib.auth import logout  # Add this import
from django.contrib.auth.decorators import login_required
from django.contrib.auth import authenticate, login
from django.contrib import messages
from django.shortcuts import render, redirect
from users.models import CustomUser

def admin_login(request):
    # Redirect to dashboard if already logged in as a superuser
    if request.user.is_authenticated and request.user.is_superuser:
        return redirect('admin_dashboard')
    
    if request.method == 'POST':
        email = request.POST.get('email')
        password = request.POST.get('password')
        user = authenticate(request, email=email, password=password)
        
        # Check if the user is a superuser
        if user and user.is_superuser:
            login(request, user)
            return redirect('admin_dashboard')
        else:
            messages.error(request, 'Invalid credentials or insufficient permissions.')
    
    return render(request, 'admin_web/login.html')

@login_required
def admin_dashboard(request):
    # Redirect to login if the user is not a superuser
    if not request.user.is_superuser:
        return redirect('admin_login')
    
    # Fetch data for the dashboard (e.g., list of users)
    users = CustomUser.objects.all()
    return render(request, 'admin_web/dashboard.html', {'users': users})

# Add this function for logout
def admin_logout(request):
    logout(request)
    return redirect('admin_login')