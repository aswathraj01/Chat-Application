from rest_framework import generics, permissions
from .models import ChatHistory
from .serializers import ChatHistorySerializer

class ChatHistoryView(generics.ListCreateAPIView):  # Handles both GET and POST
    serializer_class = ChatHistorySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return ChatHistory.objects.filter(user=self.request.user).order_by('-timestamp')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)