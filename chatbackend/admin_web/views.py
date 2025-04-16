import psutil
from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth import get_user_model
from django.db.models import Count, Sum
from support.models import SupportRequest

# Admin login view
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

# Dashboard view, accessible only by logged-in users
@login_required
def dashboard(request):
    CustomUser = get_user_model()  # Use the custom user model defined for your project
    
    # Aggregate data for total users, total logins, and total support requests
    total_users = CustomUser.objects.count()
    total_logins = CustomUser.objects.aggregate(Sum('login_count'))['login_count__sum'] or 0
    total_requests = SupportRequest.objects.count()

    # Aggregate users by region
    region_data = CustomUser.objects.values('region') \
        .annotate(user_count=Count('id')) \
        .order_by('-user_count')  # Order by the number of users

    regions = []
    user_counts = []

    for data in region_data:
        regions.append(data['region'])  # Get region name
        user_counts.append(data['user_count'])  # Get user count for each region

    # Zip the regions and user_counts together in a tuple (region, user_count)
    combined_data = zip(regions, user_counts)

    # Gather system resource utilization data using psutil
    cpu_usage = psutil.cpu_percent(interval=1)  # CPU usage in percentage
    memory_info = psutil.virtual_memory()  # Memory usage info
    memory_usage = memory_info.percent  # Memory usage in percentage
    disk_info = psutil.disk_usage('/')  # Disk usage info
    disk_usage = disk_info.percent  # Disk usage in percentage

    # Context to pass to the template
    context = {
        'combined_data': combined_data,
        'total_users': total_users,
        'total_logins': total_logins,
        'total_requests': total_requests,
        'cpu_usage': cpu_usage,
        'memory_usage': memory_usage,
        'disk_usage': disk_usage,
    }

    return render(request, 'admin_web/dashboard.html', context)

# Admin logout view
@login_required
def admin_logout(request):
    logout(request)
    return redirect('admin_login')
