from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required

def admin_login(request):
    if request.method == 'POST':
        email = request.POST['email']
        password = request.POST['password']
        user = authenticate(request, username=email, password=password)
        if user is not None:
            login(request, user)
            return redirect('dashboard')
        else:
            return render(request, 'admin_web/login.html', {'error': 'Invalid credentials'})
    return render(request, 'admin_web/login.html')

@login_required
def dashboard(request):
    return render(request, 'admin_web/dashboard.html')

@login_required
def admin_logout(request):
    logout(request)
    return redirect('admin_login')