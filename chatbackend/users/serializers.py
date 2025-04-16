from rest_framework import serializers
from .models import CustomUser
from django.contrib.auth.password_validation import validate_password
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth.models import User
from rest_framework import serializers


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ('id', 'email', 'username', 'is_admin', 'login_count')  # Added login_count

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])

    class Meta:
        model = CustomUser
        fields = ('email', 'username', 'password', 'first_name', 'last_name', 'dob', 'region')

    def create(self, validated_data):
        user = CustomUser.objects.create_user(
            email=validated_data['email'],
            username=validated_data['username'],
            password=validated_data['password'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
            dob=validated_data.get('dob'),
            region=validated_data.get('region')
        )
        return user

# Custom JWT login serializer to increment login count
class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)

        # Increment login count
        user = self.user
        user.login_count += 1
        user.save()

        # Include extra user info in the response
        data['email'] = user.email
        data['username'] = user.username
        data['is_admin'] = user.is_admin
        data['login_count'] = user.login_count

        return data

class UserUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser  # Update this to use CustomUser
        fields = ['username', 'email', 'password']
        extra_kwargs = {
            'password': {'write_only': True}  # Make password write-only
        }

    def update(self, instance, validated_data):
        # Update the username and email
        instance.username = validated_data.get('username', instance.username)
        instance.email = validated_data.get('email', instance.email)

        # If password is provided, update it
        password = validated_data.get('password', None)
        if password:
            instance.set_password(password)
        
        instance.save()
        return instance