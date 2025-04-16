from rest_framework import serializers
from .models import SupportRequest
from django.contrib.auth.models import User
from django.contrib.auth import get_user_model


User = get_user_model()  # Get the custom user model

class SupportRequestSerializer(serializers.ModelSerializer):
    user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all(), required=False)
    
    class Meta:
        model = SupportRequest
        fields = ['id', 'user', 'message', 'created_at']

    def create(self, validated_data):
        # Automatically associate the current user with the support request
        user = self.context['request'].user  # Get the logged-in user from the request context
        validated_data['user'] = user
        return super().create(validated_data)
