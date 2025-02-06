from rest_framework import serializers
from .models import ChatSession, ChatMessage

class ChatMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatMessage
        fields = ('role', 'content', 'timestamp')

class ChatSessionSerializer(serializers.ModelSerializer):
    messages = ChatMessageSerializer(many=True)
    
    class Meta:
        model = ChatSession
        fields = ('id', 'title', 'created_at', 'messages')