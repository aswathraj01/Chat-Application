# support/views.py

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import SupportRequest
import json

@csrf_exempt
def create_support_request(request):
    try:
        # Parse the incoming JSON data
        data = json.loads(request.body)
        name = data.get('name')
        email = data.get('email')
        message = data.get('message')

        # Validate the data (basic validation)
        if not name or not email or not message:
            return JsonResponse({'error': 'All fields are required.'}, status=400)

        # Create the support request object
        support_request = SupportRequest.objects.create(
            name=name,
            email=email,
            message=message
        )

        # Respond with success message
        return JsonResponse({'success': 'Support request submitted successfully.'}, status=200)

    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)