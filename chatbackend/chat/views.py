from rest_framework import generics, permissions
from .models import ChatSession, ChatMessage
from .serializers import ChatSessionSerializer
from users.models import CustomUser

class ChatSessionView(generics.ListCreateAPIView):
    serializer_class = ChatSessionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return ChatSession.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        messages_data = self.request.data.get('messages', [])
        session = serializer.save(
            user=self.request.user,
            title=messages_data[0]['content'][:50] if messages_data else 'New Chat'
        )
        
        for msg in messages_data:
            ChatMessage.objects.create(
                session=session,
                role=msg['role'],
                content=msg['content']
            )