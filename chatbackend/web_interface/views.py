# backend/web_interface/views.py
from django.shortcuts import render

def chat(request):
    return render(request, 'web_interface/chat.html')