from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth import get_user_model
from django.shortcuts import render
from django.db.models import Sum
from support.models import SupportRequest
 


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
    CustomUser = get_user_model()
    total_users = CustomUser.objects.count()
    total_logins = CustomUser.objects.aggregate(Sum('login_count'))['login_count__sum'] or 0
    total_requests = SupportRequest.objects.count()

    return render(request, 'admin_web/dashboard.html', {
        'total_users': total_users,
        'total_logins': total_logins,
        'total_requests': total_requests,
    })

@login_required
def admin_logout(request):
    logout(request)
    return redirect('admin_login')

