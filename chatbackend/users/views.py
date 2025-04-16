from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView
from .serializers import RegisterSerializer, UserSerializer, CustomTokenObtainPairSerializer, UserUpdateSerializer  # Import UserUpdateSerializer correctly
from .models import CustomUser
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated

class RegisterView(generics.CreateAPIView):
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        refresh = RefreshToken.for_user(user)
        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'is_admin': user.is_admin,
        }, status=status.HTTP_201_CREATED)

class UserInfoView(generics.RetrieveAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user

# Custom Login View that uses CustomTokenObtainPairSerializer
class CustomLoginView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer


@api_view(['PUT'])
@permission_classes([IsAuthenticated])  # Ensure the user is authenticated
def update_user(request):
    """
    View to update the user details (username, email, and password).
    """
    user = request.user  # Get the authenticated user
    serializer = UserUpdateSerializer(user, data=request.data)

    if serializer.is_valid():
        # Save the updated user data
        serializer.save()
        return Response({'message': 'User updated successfully'}, status=status.HTTP_200_OK)
    
    # If the data is not valid, return an error response
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
