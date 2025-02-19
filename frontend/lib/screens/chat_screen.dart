import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'user_settings_screen.dart';

class ChatHistoryItem {
  final String message;
  final String response;
  final String timestamp;

  ChatHistoryItem({
    required this.message,
    required this.response,
    required this.timestamp,
  });

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) {
    return ChatHistoryItem(
      message: json['message'],
      response: json['response'],
      timestamp: json['timestamp'],
    );
  }
}

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
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '';
  bool _isMicPressed = false;
  final ScrollController _scrollController = ScrollController();
  final _storage = const FlutterSecureStorage();
  List<ChatHistoryItem> messageHistory = [];

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
    _speech = stt.SpeechToText();
    _initializeSpeech();
    _loadMessageHistory();
  }

  void _initializeSpeech() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {});
    } else {
      print("Speech recognition not available");
    }
  }

  Future<void> _loadMessageHistory() async {
    try {
      final String? accessToken = await _storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/chat/history/"),
        headers: {"Authorization": "Bearer $accessToken"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          messageHistory =
              data.map((item) => ChatHistoryItem.fromJson(item)).toList();
        });
      }
    } catch (e) {
      print("Error loading message history: $e");
    }
  }

  Future<void> _saveMessageHistory(String message, String response) async {
    try {
      final String? accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) return;

      final res = await http.post(
        Uri.parse("http://localhost:8000/api/chat/history/"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json"
        },
        body: json.encode({
          'message': message,
          'response': response,
        }),
      );

      if (res.statusCode == 201) {
        await _loadMessageHistory();
      }
    } catch (e) {
      print("Error saving message history: $e");
    }
  }

  void _startListening() async {
    if (!_isListening) {
      setState(() {
        _isListening = true;
        _isMicPressed = true;
      });
      _speech.listen(
        onResult: (result) =>
            setState(() => _recognizedText = result.recognizedWords),
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
      final String? accessToken = await _storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/userinfo/"),
        headers: {"Authorization": "Bearer $accessToken"},
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
    _controller.clear();

    setState(() {
      chatMessages.add({"role": "user", "content": message});
      _scrollToBottom();
    });

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
        final aiResponse = responseData["message"]["content"];

        setState(() {
          chatMessages.add({"role": "system", "content": aiResponse});
          _scrollToBottom();
        });

        await _saveMessageHistory(prompt, aiResponse);
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
        duration: const Duration(milliseconds: 300),
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
          title: const Text("AI Chat App"),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Chat History"),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 400,
                    child: messageHistory.isEmpty
                        ? const Center(child: Text("No chat history available"))
                        : ListView.builder(
                            itemCount: messageHistory.length,
                            itemBuilder: (context, index) {
                              final item = messageHistory[index];
                              return ListTile(
                                title: Text(item.message),
                                subtitle: Text(item.response),
                                trailing: Text(item.timestamp),
                              );
                            },
                          ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handlePopupSelection(value),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'New Chat',
                  child: Row(
                    children: [
                      Icon(Icons.add, color: buttonColor),
                      const SizedBox(width: 8),
                      const Text('New Chat'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'Font Size',
                  child: Row(
                    children: [
                      Icon(Icons.font_download, color: buttonColor),
                      const SizedBox(width: 8),
                      const Text('Font Size'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'User Settings',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: buttonColor),
                      const SizedBox(width: 8),
                      const Text('User Settings'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: isDarkMode ? 'Toggle Light Mode' : 'Toggle Dark Mode',
                  child: Row(
                    children: [
                      Icon(Icons.dark_mode, color: buttonColor),
                      const SizedBox(width: 8),
                      Text(isDarkMode
                          ? 'Toggle Light Mode'
                          : 'Toggle Dark Mode'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'About',
                  child: Row(
                    children: [
                      Icon(Icons.info, color: buttonColor),
                      const SizedBox(width: 8),
                      const Text('About'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'Logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: buttonColor),
                      const SizedBox(width: 8),
                      const Text('Logout'),
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
                            if (index == 0) return const SizedBox.shrink();
                            return _buildMessageBubble(chatMessages[index]);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                                controller: _controller,
                                decoration: const InputDecoration(
                                  labelText: "Enter your prompt",
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: _sendMessage,
                                onChanged: (_) => setState(() {})),
                          ),
                          const SizedBox(width: 8),
                          _controller.text.isEmpty
                              ? _buildMicButton(buttonColor!)
                              : _buildSendButton(buttonColor!),
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
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
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
        padding: const EdgeInsets.all(12),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.send, color: Colors.white),
      ),
    );
  }

  Widget _buildHistoryView() {
    return Column(
      children: [
        Text(
          'Chat Sessions',
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
                margin: const EdgeInsets.symmetric(vertical: 8),
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
          child: const Text('Back to Chat'),
        ),
      ],
    );
  }

  void _handlePopupSelection(String value) {
    if (value == 'New Chat') {
      _startNewChat();
    } else if (value == 'Font Size') {
      _showSettingsFontDialog();
    } else if (value == 'Toggle Dark Mode' || value == 'Toggle Light Mode') {
      _toggleDarkMode();
    } else if (value == 'About') {
      _showAboutDialog();
    } else if (value == 'Logout') {
      _logoutUser();
    } else if (value == 'User Settings') {
      _userSettings();
    }
  }

  void _logoutUser() async {
    await _storage.delete(key: 'access_token');
    Navigator.pushReplacementNamed(
        // ignore: use_build_context_synchronously
        context,
        '/login');
  }

  void _userSettings() {
    Navigator.pushNamed(context, '/user-settings');
  }

  void _showSettingsFontDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Font Size"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      "Current Size: ${fontSize.toInt()}"), // Show current value
                  Slider(
                    value: fontSize,
                    min: 12,
                    max: 30,
                    divisions: 18, // Creates discrete intervals
                    label: fontSize.toInt().toString(), // Show value on drag
                    onChanged: (newSize) {
                      // Update both dialog state and parent state
                      setState(() => fontSize = newSize); // Update main UI
                      setStateDialog(
                          () => fontSize = newSize); // Update dialog UI
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'AI Chat Application',
      applicationVersion: '1.1.3',
      children: const [
        Text('This is a chat app powered by Llama AI and uses Ollama Model 3.2')
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
    // Implement settings save logic
  }
}
