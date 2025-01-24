from django.contrib.auth import authenticate
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json
import re
from django.contrib.auth import get_user_model


# Password validation function
def is_strong_password(password):
    """
    A simple password strength validator that checks for:
    - At least 8 characters long
    - Contains both uppercase and lowercase letters
    - Contains at least one digit
    """
    if len(password) < 8:
        return False
    if not re.search("[a-z]", password):
        return False
    if not re.search("[A-Z]", password):
        return False
    if not re.search("[0-9]", password):
        return False
    return True


@csrf_exempt
def SignUpView(request):
    if request.method == 'POST':
        try:
            # Parse the incoming JSON request body
            data = json.loads(request.body)
            username = data.get('username')
            password = data.get('password')
            email = data.get('email')  # Add email field
            first_name = data.get('first_name', '')
            last_name = data.get('last_name', '')

            # Log the incoming data for debugging
            print(f"Received data: {data}")

            # Validate input data
            if not username or not password or not email:
                return JsonResponse({'error': 'Username, password, and email are required'}, status=400)

            # Validate password strength
            if not is_strong_password(password):
                return JsonResponse({'error': 'Password must be at least 8 characters long, include uppercase and lowercase letters, and contain at least one digit'}, status=400)

            # Check if the username already exists
            User = get_user_model()  # This ensures using the custom user model
            if User.objects.filter(username=username).exists():
                return JsonResponse({'error': 'Username already exists'}, status=400)

            # Create a new user
            user = User.objects.create_user(username=username, password=password, email=email, first_name=first_name, last_name=last_name)

            # Return success response
            return JsonResponse({'message': 'User created successfully'}, status=201)

        except Exception as e:
            # Log the error for debugging
            print(f"Error: {e}")
            return JsonResponse({'error': f'Something went wrong: {str(e)}'}, status=500)

    return JsonResponse({'error': 'Invalid request method'}, status=400)


@csrf_exempt
def LoginView(request):
    if request.method == 'POST':
        try:
            # Parse the incoming JSON request body
            data = json.loads(request.body)
            username = data.get('username')
            password = data.get('password')

            # Validate input data
            if not username or not password:
                return JsonResponse({'error': 'Username and password are required'}, status=400)

            # Authenticate the user
            user = authenticate(request, username=username, password=password)

            # Check if authentication was successful
            if user is not None:
                return JsonResponse({'message': 'Login successful'}, status=200)
            else:
                return JsonResponse({'error': 'Invalid credentials'}, status=400)

        except Exception as e:
            # Log the error for debugging
            print(f"Error: {e}")
            return JsonResponse({'error': f'Something went wrong: {str(e)}'}, status=500)

    return JsonResponse({'error': 'Invalid request method'}, status=400)
