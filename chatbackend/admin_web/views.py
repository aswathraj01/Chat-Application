import psutil
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth import get_user_model
from django.db.models import Count, Sum
from support.models import SupportRequest
from django.contrib import messages
from django.core.exceptions import ValidationError
from django.http import HttpResponseRedirect
from django.shortcuts import render
from django.db.models import Count
from django.utils import timezone
from django.db.models.functions import TruncMonth
from users.models import CustomUser
from chat.models import ChatHistory
import json


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
    CustomUser = get_user_model()

    total_users = CustomUser.objects.count()
    total_logins = CustomUser.objects.aggregate(Sum('login_count'))['login_count__sum'] or 0
    total_requests = SupportRequest.objects.count()

    region_data = CustomUser.objects.values('region') \
        .annotate(user_count=Count('id')) \
        .order_by('-user_count')

    regions = []
    user_counts = []

    for data in region_data:
        regions.append(data['region'])
        user_counts.append(data['user_count'])

    combined_data = zip(regions, user_counts)

    # Get system statistics
    cpu_usage = psutil.cpu_percent(interval=1)
    memory_info = psutil.virtual_memory()
    memory_usage = memory_info.percent
    disk_info = psutil.disk_usage('/')
    disk_usage = disk_info.percent

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

# ✅ User list view
@login_required
def user_list(request):
    CustomUser = get_user_model()
    users = CustomUser.objects.all().order_by('first_name', 'last_name')
    return render(request, 'admin_web/users.html', {'users': users})

# Edit User view
@login_required
def edit_user(request, user_id):
    CustomUser = get_user_model()
    user = get_object_or_404(CustomUser, id=user_id)

    if request.method == 'POST':
        # Get the form data from the POST request
        first_name = request.POST.get('first_name')
        last_name = request.POST.get('last_name')
        email = request.POST.get('email')
        dob = request.POST.get('dob')
        region = request.POST.get('region')
        is_admin = request.POST.get('is_admin') == 'on'

        # Update user details
        user.first_name = first_name
        user.last_name = last_name
        user.email = email
        user.dob = dob
        user.region = region
        user.is_admin = is_admin  # Handling the checkbox for admin status

        try:
            user.save()
            messages.success(request, 'User details updated successfully.')
        except Exception as e:
            messages.error(request, 'An error occurred while saving the user details.')

        return redirect('user_list')  # Redirect to the user list after saving

    return render(request, 'admin_web/edit_user.html', {'user': user})

# Delete User view
@login_required
def delete_user(request, user_id):
    CustomUser = get_user_model()
    user = get_object_or_404(CustomUser, id=user_id)

    if request.method == 'POST':
        try:
            user.delete()
            messages.success(request, 'User deleted successfully.')
        except Exception as e:
            messages.error(request, f'Error deleting user: {str(e)}')
        return redirect('user_list')  # Redirect to the user list after deletion

    return render(request, 'admin_web/confirm_delete_user.html', {'user': user})

# Disable user account
@login_required
def disable_user(request, user_id):
    CustomUser = get_user_model()
    user = get_object_or_404(CustomUser, id=user_id)
    user.is_active = False  # Set is_active to False to disable the user
    user.save()
    messages.success(request, 'User account disabled.')
    return redirect('user_list')


# Activate user account
@login_required
def activate_user(request, user_id):
    CustomUser = get_user_model()
    user = get_object_or_404(CustomUser, id=user_id)
    user.is_active = True  # Set is_active to True to activate the user
    user.save()
    messages.success(request, 'User account activated.')
    return redirect('user_list')

@login_required
def roles_view(request):
    CustomUser = get_user_model()
    users = CustomUser.objects.all()  # Get all users
    return render(request, 'admin_web/roles.html', {'users': users})

@login_required
def change_role(request, user_id):
    CustomUser = get_user_model()
    user = get_object_or_404(CustomUser, id=user_id)

    # Toggle the super_user or is_admin role between True and False
    if user.is_admin:
        user.is_admin = False
        messages.success(request, f"User {user.username}'s role has been changed to User.")
    else:
        user.is_admin = True
        messages.success(request, f"User {user.username}'s role has been changed to Admin.")
    
    user.save()
    
    # Redirect back to the roles page
    return HttpResponseRedirect(request.META.get('HTTP_REFERER', '/'))


# Chart view (for displaying charts)
@login_required
def chart_view(request):
    # Get the current date for filtering messages within the last 12 months
    current_date = timezone.now()

    # Fetch the number of messages per month for the last 12 months
    messages_per_month = (
        ChatHistory.objects
        .annotate(month=TruncMonth('timestamp'))
        .filter(timestamp__gte=current_date - timezone.timedelta(days=365))
        .values('month')
        .annotate(message_count=Count('id'))
        .order_by('month')
    )

    messages_per_month_data = [
        {'month': message['month'].strftime('%Y-%m'), 'message_count': message['message_count']}
        for message in messages_per_month
    ]

    # Pass the data to the template
    context = {
        'messages_per_month_data': messages_per_month_data,
    }
    
    # Fetch the number of users per country
    users_per_country = (
        CustomUser.objects
        .values('region')
        .annotate(user_count=Count('id'))
        .order_by('region')
    )

    users_per_country_data = [
        {'region': user['region'], 'user_count': user['user_count']}
        for user in users_per_country
    ]

    # Pass the data to the template
    context = {
        'users_per_country_data': users_per_country_data,
    }

    # System resource utilization using psutil
    cpu_usage = psutil.cpu_percent()
    memory_usage = psutil.virtual_memory().percent
    disk_usage = psutil.disk_usage('/').percent

    context = {
        'messages_per_month_data': messages_per_month_data,
        'users_per_country_data': users_per_country_data,
        'cpu_usage': cpu_usage,
        'memory_usage': memory_usage,
        'disk_usage': disk_usage,
    }

    print("CPU:", cpu_usage)
    print("Memory:", memory_usage)
    print("Disk:", disk_usage)


    return render(request, 'admin_web/chart.html', context)