import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> chatMessages = [
    {"role": "system", "content": "You are a helpful assistant."},
  ];
  bool isDarkMode = false;
  bool showHistory = false;
  final List<List<Map<String, String>>> chatHistory = [];
  double fontSize = 16;
  String username = "Loading...";
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // Speech-to-Text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '';
  bool _isMicPressed = false;
  bool _isSendPressed = false;

  // ScrollController
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
    _speech = stt.SpeechToText();
    _initializeSpeech();
  }

  void _initializeSpeech() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {});
    } else {
      print("Speech recognition not available");
    }
  }

  void _startListening() async {
    if (!_isListening) {
      setState(() {
        _isListening = true;
        _isMicPressed = true;
      });
      _speech.listen(
        onResult: (result) => setState(() => _recognizedText = result.recognizedWords),
      );
    }
  }

  void _stopListening() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
        _isMicPressed = false;
      });
      _speech.stop();
      if (_recognizedText.isNotEmpty) {
        _sendMessage(_recognizedText);
        _recognizedText = '';
      }
    }
  }

  void _cancelListening() {
    if (_isListening) {
      setState(() {
        _isListening = false;
        _isMicPressed = false;
        _recognizedText = '';
      });
      _speech.stop();
    }
  }

  Future<void> fetchUserInfo() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/userinfo/"),
        headers: {"Authorization": "Bearer your_token_here"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          username = data['username'] ?? "Unknown User";
        });
      }
    } catch (e) {
      setState(() {
        username = "Error fetching user";
      });
    }
  }

  void _sendMessage(String message) {
    if (message.isEmpty) return;
    
    // Clear input immediately
    _controller.clear();
    
    // Add user message and scroll
    setState(() {
      chatMessages.add({"role": "user", "content": message});
      _scrollToBottom();
    });

    // Send to backend
    _queryToLlama(message);
  }

  Future<void> _queryToLlama(String prompt) async {
    final data = {
      "model": "llama3.2",
      "messages": chatMessages,
      "stream": false,
    };

    try {
      final response = await http.post(
        Uri.parse("http://localhost:11434/api/chat"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          chatMessages.add({
            "role": "system",
            "content": responseData["message"]["content"],
          });
          _scrollToBottom();
        });
      } else {
        setState(() => chatMessages.removeLast());
      }
    } catch (e) {
      setState(() => chatMessages.removeLast());
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = isDarkMode ? Colors.deepPurple[800] : Colors.blue;

    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Ai Chat App"),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'New Chat') {
                  _startNewChat();
                } else if (value == 'Settings') {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Settings"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Font Size:"),
                          Slider(
                            value: fontSize,
                            min: 12,
                            max: 30,
                            onChanged: (newSize) {
                              setState(() => fontSize = newSize);
                            },
                          ),
                          Text("Username:"),
                          TextField(controller: usernameController..text = username),
                          Text("Password:"),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                          ),
                          Text("Email:"),
                          TextField(controller: emailController),
                          ElevatedButton(
                            onPressed: _saveUserSettings,
                            child: Text("Save Settings"),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (value == 'Toggle Dark Mode' || value == 'Toggle Light Mode') {
                  _toggleDarkMode();
                } else if (value == 'View History') {
                  _toggleHistoryView();
                } else if (value == 'About') {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Ai Chat Application',
                    applicationVersion: '1.1.3',
                    children: [
                      Text('This is a chat app powered by Llama AI and uses Ollama Model 3.2')
                    ],
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'New Chat',
                  child: Row(
                    children: [
                      Icon(Icons.add, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('New Chat'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'Settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: isDarkMode ? 'Toggle Light Mode' : 'Toggle Dark Mode',
                  child: Row(
                    children: [
                      Icon(Icons.dark_mode, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(isDarkMode ? 'Toggle Light Mode' : 'Toggle Dark Mode'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'View History',
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('View History'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'About',
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('About'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: showHistory 
                ? _buildHistoryView()
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: chatMessages.length,
                          itemBuilder: (context, index) {
                            if (index == 0) return SizedBox.shrink();
                            final message = chatMessages[index];
                            return _buildMessageBubble(message);
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                labelText: "Enter your prompt",
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: _sendMessage,
                            ),
                          ),
                          SizedBox(width: 8),
                          if (_controller.text.isEmpty)
                            _buildMicButton(buttonColor!),
                          if (_controller.text.isNotEmpty)
                            _buildSendButton(buttonColor!),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    final isSystem = message["role"] == 'system';
    final messageColor = isSystem
        ? (isDarkMode ? Colors.grey[900]! : Colors.grey[200]!)
        : (isDarkMode ? Colors.deepPurple[800]! : Colors.blue[300]!);
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Align(
      alignment: isSystem ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: messageColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message["content"]!,
          style: TextStyle(color: textColor, fontSize: fontSize),
        ),
      ),
    );
  }

  Widget _buildMicButton(Color buttonColor) {
    return GestureDetector(
      onLongPressStart: (_) => _startListening(),
      onLongPressEnd: (_) => _stopListening(),
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) _cancelListening();
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isMicPressed ? Colors.grey[300]! : buttonColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.mic,
          color: _isMicPressed ? Colors.grey[600]! : Colors.white,
        ),
      ),
    );
  }

  Widget _buildSendButton(Color buttonColor) {
    return GestureDetector(
      onTap: () => _sendMessage(_controller.text),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.send, color: Colors.white),
      ),
    );
  }

  Widget _buildHistoryView() {
    return Column(
      children: [
        Text(
          'Chat History',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: chatHistory.length,
            itemBuilder: (context, index) {
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: chatHistory[index].map((msg) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          "${msg['role']}: ${msg['content']}",
                          style: TextStyle(fontSize: fontSize),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
        ElevatedButton(
          onPressed: _toggleHistoryView,
          child: Text('Back to Chat'),
        ),
      ],
    );
  }

  void _startNewChat() {
    setState(() {
      chatHistory.add(List.from(chatMessages));
      chatMessages = [
        {"role": "system", "content": "You are a helpful assistant."}
      ];
    });
  }

  void _toggleDarkMode() => setState(() => isDarkMode = !isDarkMode);
  void _toggleHistoryView() => setState(() => showHistory = !showHistory);
  
  void _saveUserSettings() {
    final updatedData = {
      'username': usernameController.text,
      'password': passwordController.text,
      'email': emailController.text,
    };
    // Implement API call to save settings
  }
}