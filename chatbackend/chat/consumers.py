import json
from channels.generic.websocket import AsyncWebsocketConsumer
from django.urls import re_path

class AdminChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        await self.channel_layer.group_add("admin_chat_monitor", self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard("admin_chat_monitor", self.channel_name)

    async def receive(self, text_data):
        # Broadcast messages to admin group (optional)
        pass

    async def send_new_message(self, event):
        await self.send(text_data=json.dumps(event["message"]))

websocket_urlpatterns = [
    re_path(r'ws/admin/chat/$', AdminChatConsumer.as_asgi()),
]