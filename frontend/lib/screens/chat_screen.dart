import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:clipboard/clipboard.dart'; // For message copying
import 'package:flutter/services.dart'; // For Clipboard and ClipboardData
import 'package:flutter_tts/flutter_tts.dart'; // Add this import

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
  List<Map<String, dynamic>> chatMessages = [
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
  bool isTyping = false; // Typing indicator
  List<String> pinnedMessages = []; // Pinned messages
  Map<int, List<String>> messageReactions = {}; // Message reactions
  final FlutterTts _flutterTts = FlutterTts(); // Add this line

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
    setState(() {
      isTyping = true; // Show typing indicator
    });

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
    } finally {
      setState(() {
        isTyping = false; // Hide typing indicator
      });
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

  // Feature: Add reaction to a message
  void _addReaction(int messageIndex, String reaction) {
    setState(() {
      if (messageReactions[messageIndex] == null) {
        messageReactions[messageIndex] = [];
      }
      messageReactions[messageIndex]!.add(reaction);
    });
  }

  // Feature: Edit a message
  void _updateMessage(int messageIndex, String newContent) {
    setState(() {
      chatMessages[messageIndex]['content'] = newContent;
    });
  }

  // Feature: Pin a message
  void _togglePinMessage(int messageIndex) {
    setState(() {
      if (pinnedMessages.contains(chatMessages[messageIndex]['content'])) {
        pinnedMessages.remove(chatMessages[messageIndex]['content']);
      } else {
        pinnedMessages.add(chatMessages[messageIndex]['content']);
      }
    });
  }

  // Feature: Copy a message to clipboard
  void _copyMessage(String message) {
    Clipboard.setData(ClipboardData(text: message)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message copied to clipboard')),
      );
    });
  }

  // Feature: Translate a message
  void _translateMessage(int messageIndex) async {
    final message = chatMessages[messageIndex]['content'];
    final response = await http.post(
      Uri.parse("https://translation-api.com/translate"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        'text': message,
        'target_language': 'es', // Translate to Spanish
      }),
    );

    if (response.statusCode == 200) {
      final translatedText = json.decode(response.body)['translated_text'];
      setState(() {
        chatMessages[messageIndex]['translated'] = translatedText;
      });
    }
  }

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                ListTile(
                  title: const Text('English'),
                  onTap: () {
                    Navigator.pop(context);
                    _sendLanguageSelectionMessage('en');
                  },
                ),
                ListTile(
                  title: const Text('Hindi'),
                  onTap: () {
                    Navigator.pop(context);
                    _sendLanguageSelectionMessage('hindi');
                  },
                ),
                ListTile(
                  title: const Text('Malayalam'),
                  onTap: () {
                    Navigator.pop(context);
                    _sendLanguageSelectionMessage('malayalam');
                  },
                ),
                ListTile(
                  title: const Text('Japanese'),
                  onTap: () {
                    Navigator.pop(context);
                    _sendLanguageSelectionMessage('ja');
                  },
                ),
                // Add more languages as needed
              ],
            ),
          ),
        );
      },
    );
  }

  void _sendLanguageSelectionMessage(String languageCode) {
    final message = "Translate all responses to '$languageCode'";
    _sendMessage(message);
  }

  void _showChatHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Chat History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: messageHistory.length,
                itemBuilder: (context, index) {
                  final item = messageHistory[index];
                  return ListTile(
                    title: Text(item.message),
                    subtitle: Text(item.response),
                    trailing: Text(item.timestamp),
                    onTap: () {
                      Navigator.pop(context);
                      _loadChatSession(index);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _loadChatSession(int index) {
    setState(() {
      chatMessages = [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": messageHistory[index].message},
        {"role": "system", "content": messageHistory[index].response},
      ];
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
              onPressed: _showChatHistory,
            ),
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: _showLanguageSelectionDialog,
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
                      if (pinnedMessages.isNotEmpty)
                        Column(
                          children: [
                            const Text(
                              'Pinned Messages',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ...pinnedMessages.map((message) {
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.yellow[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(message),
                              );
                            }).toList(),
                          ],
                        ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: chatMessages.length,
                          itemBuilder: (context, index) {
                            if (index == 0) return const SizedBox.shrink();
                            return _buildMessageBubble(
                                chatMessages[index], index);
                          },
                        ),
                      ),
                      if (isTyping)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('AI is typing...'),
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

  Widget _buildMessageBubble(Map<String, dynamic> message, int index) {
    final isSystem = message["role"] == 'system';
    final messageColor = isSystem
        ? (isDarkMode ? Colors.grey[900]! : Colors.grey[200]!)
        : (isDarkMode ? Colors.deepPurple[800]! : Colors.blue[300]!);
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return GestureDetector(
      onLongPress: () {
        if (!isSystem) {
          _showMessageOptions(context, index);
        }
      },
      child: Align(
        alignment: isSystem ? Alignment.centerLeft : Alignment.centerRight,
        child: Row(
          mainAxisSize:
              MainAxisSize.min, // Ensure the row doesn't expand unnecessarily
          crossAxisAlignment:
              CrossAxisAlignment.end, // Align items at the bottom
          children: [
            if (isSystem) // Copy and Delete icons for received (system) messages
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      size: 16,
                      color: textColor.withOpacity(0.7),
                    ),
                    onPressed: () => _copyMessage(message["content"]),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.volume_up,
                      size: 16,
                      color: textColor.withOpacity(0.7),
                    ),
                    onPressed: () => _speakMessage(message["content"]),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      size: 16,
                      color: textColor.withOpacity(0.7),
                    ),
                    onPressed: () => _deleteMessage(index),
                  ),
                ],
              ),
            if (!isSystem) // Edit and Delete icons for sent (user) messages
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      size: 16,
                      color: textColor.withOpacity(0.7),
                    ),
                    onPressed: () => _editMessage(index),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      size: 16,
                      color: textColor.withOpacity(0.7),
                    ),
                    onPressed: () => _deleteMessage(index),
                  ),
                ],
              ),
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: messageColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message["content"]!,
                      style: TextStyle(color: textColor, fontSize: fontSize),
                    ),
                    if (message['translated'] != null)
                      Text(
                        message['translated'],
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: fontSize * 0.8,
                        ),
                      ),
                    if (messageReactions[index] != null)
                      Wrap(
                        children: messageReactions[index]!.map((reaction) {
                          return Text(reaction);
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editMessage(int messageIndex) async {
    final message = chatMessages[messageIndex]['content'];

    // Show a dialog to edit the message
    TextEditingController editController = TextEditingController(text: message);
    final newMessage = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Message'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(
              labelText: 'Edit your message',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, editController.text);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newMessage != null && newMessage.isNotEmpty) {
      // Update the message in the chat
      setState(() {
        chatMessages[messageIndex]['content'] = newMessage;
      });

      // Remove the old AI response (if any)
      if (messageIndex + 1 < chatMessages.length &&
          chatMessages[messageIndex + 1]['role'] == 'system') {
        setState(() {
          chatMessages.removeAt(messageIndex + 1);
        });
      }

      // Re-send the edited message to the AI
      _queryToLlama(newMessage);
    }
  }

  void _showMessageOptions(BuildContext context, int messageIndex) {
    final isSystem = chatMessages[messageIndex]['role'] == 'system';

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSystem) // Edit option for sent messages
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(messageIndex);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                _deleteMessage(messageIndex);
                Navigator.pop(context);
              },
            ),
            if (isSystem) // Copy option for received messages
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  _copyMessage(chatMessages[messageIndex]['content']);
                  Navigator.pop(context);
                },
              ),
          ],
        );
      },
    );
  }

// Keep this single instance of _deleteMessage
  void _deleteMessage(int messageIndex) {
    setState(() {
      // Remove the message at the specified index
      chatMessages.removeAt(messageIndex);

      // If the deleted message is a user message, also remove the AI response (if any)
      if (messageIndex < chatMessages.length &&
          chatMessages[messageIndex]['role'] == 'system') {
        chatMessages.removeAt(messageIndex);
      }
    });
  }

  void _showReactionPicker(BuildContext context, int messageIndex) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              title: const Text('👍'),
              onTap: () {
                _addReaction(messageIndex, '👍');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('❤️'),
              onTap: () {
                _addReaction(messageIndex, '❤️');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('😂'),
              onTap: () {
                _addReaction(messageIndex, '😂');
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, int messageIndex) {
    TextEditingController editController = TextEditingController(
      text: chatMessages[messageIndex]['content'],
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Message'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(
              labelText: 'Edit your message',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateMessage(messageIndex, editController.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSendButton(Color buttonColor) {
    return IconButton(
      icon: Icon(Icons.send, color: buttonColor),
      onPressed: () => _sendMessage(_controller.text),
    );
  }

  Widget _buildMicButton(Color buttonColor) {
    return IconButton(
      icon:
          Icon(_isMicPressed ? Icons.mic : Icons.mic_none, color: buttonColor),
      onPressed: _isMicPressed ? _stopListening : _startListening,
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

  void _speakMessage(String message) async {
    await _flutterTts.setLanguage("en-US"); // Set language to US English

    // Set a higher pitch for a more female-like voice
    await _flutterTts.setPitch(
        2.6); // Adjust pitch (1.0 is default, higher values make it more female-like)

    // Set a slightly slower speech rate for more natural speech
    await _flutterTts.setSpeechRate(
        0.9); // Adjust speech rate (1.0 is default, lower values make it slower)

    // Optionally, set a specific voice if available
    // Check available voices using _flutterTts.getVoices() and select a female voice
    // Example:
    // var voices = await _flutterTts.getVoices();
    // var femaleVoice = voices.firstWhere((voice) => voice.name.contains("female"));
    // await _flutterTts.setVoice(femaleVoice);

    await _flutterTts.speak(message);
  }

  @override
  void dispose() {
    _flutterTts.stop(); // Stop any ongoing speech
    super.dispose();
  }
}
