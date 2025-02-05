from rest_framework import generics, permissions
from .models import User, ChatHistory, UserSettings
from .serializers import UserSerializer, ChatHistorySerializer, UserSettingsSerializer

# User views
class UserListCreateView(generics.ListCreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer

class UserDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer

# Chat history views
class ChatHistoryListView(generics.ListCreateAPIView):
    serializer_class = ChatHistorySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return ChatHistory.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

# User settings views
class UserSettingsView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSettingsSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return UserSettings.objects.get(user=self.request.user)