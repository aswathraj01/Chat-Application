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
  String username = "Loading..."; // Default username
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // Speech-to-Text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '';
  bool _isMicPressed = false; // Track if mic button is pressed
  bool _isSendPressed = false; // Track if send button is pressed

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
    _speech = stt.SpeechToText();
    _initializeSpeech();
  }

  // Initialize speech recognition
  void _initializeSpeech() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {});
    } else {
      print("Speech recognition not available");
    }
  }

  // Start listening to user's voice
  void _startListening() async {
    if (!_isListening) {
      setState(() {
        _isListening = true;
        _isMicPressed = true; // Mic button is pressed
      });
      _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true, // Enable partial results
        ),
      );
      print("Started listening...");
    }
  }

  // Stop listening
  void _stopListening() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
        _isMicPressed = false; // Mic button is released
      });
      _speech.stop();
      if (_recognizedText.isNotEmpty) {
        query(_recognizedText); // Directly send the recognized text
        _recognizedText = ''; // Clear the recognized text
      }
      print("Stopped listening...");
    }
  }

  // Cancel listening
  void _cancelListening() {
    if (_isListening) {
      setState(() {
        _isListening = false;
        _isMicPressed = false; // Mic button is released
        _recognizedText = ''; // Clear the recognized text
      });
      _speech.stop();
      print("Cancelled listening...");
    }
  }

  // Function to fetch the user info from the backend (Django)
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

  Future<void> query(String prompt) async {
    final message = {
      "role": "user",
      "content": prompt,
    };

    chatMessages.add(message);

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
        chatMessages.add(
          {
            "role": "system",
            "content": responseData["message"]["content"],
          },
        );

        _controller.clear();
        setState(() {});
      } else {
        chatMessages.remove(message);
        setState(() {});
      }
    } catch (e) {
      chatMessages.remove(message);
    }
  }

  void _startNewChat() {
    setState(() {
      chatHistory.add(List<Map<String, String>>.from(chatMessages));
      chatMessages = [
        {"role": "system", "content": "You are a helpful assistant."},
      ];
      _controller.clear();
    });
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _toggleHistoryView() {
    setState(() {
      showHistory = !showHistory;
    });
  }

  void _saveUserSettings() {
    // You can implement an API call to save the settings
    final updatedData = {
      'username': usernameController.text,
      'password': passwordController.text,
      'email': emailController.text,
    };
    // Send a PUT request to update user details on the backend
  }

  @override
  Widget build(BuildContext context) {
    // Define button colors based on dark mode
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
                  // Navigate to settings page
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
                              setState(() {
                                fontSize = newSize;
                              });
                            },
                          ),
                          Text("Username:"),
                          TextField(
                            controller: usernameController..text = username,
                          ),
                          Text("Password:"),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                          ),
                          Text("Email:"),
                          TextField(
                            controller: emailController,
                          ),
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
                      Text(
                          'This is a chat app powered by Llama AI and uses Ollama Model 3.2')
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
                ? Column(
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
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
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: chatMessages.length,
                          itemBuilder: (context, index) {
                            if (index == 0) return SizedBox.shrink();
                            final message = chatMessages[index];

                            // Define the colors for light and dark mode
                            final messageColor = message["role"] == 'system'
                                ? (isDarkMode
                                    ? Colors.grey[900]
                                    : Colors.grey[200])
                                : (isDarkMode
                                    ? Colors.deepPurple[800]
                                    : Colors.blue[300]);

                            final textColor = message["role"] == 'system'
                                ? (isDarkMode ? Colors.white : Colors.black)
                                : (isDarkMode ? Colors.white : Colors.black);

                            return Align(
                              alignment: message["role"] == 'system'
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 8),
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: messageColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  message["content"] ?? '',
                                  style: TextStyle(
                                      color: textColor, fontSize: fontSize),
                                ),
                              ),
                            );
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
                              onChanged: (text) {
                                setState(() {});
                              },
                              onSubmitted: (text) {
                                if (_controller.text.isNotEmpty) {
                                  query(_controller.text);
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          // Show mic button only when text field is empty
                          if (_controller.text.isEmpty)
                            GestureDetector(
                              onLongPressStart: (_) {
                                _startListening();
                              },
                              onLongPressEnd: (_) {
                                _stopListening();
                              },
                              onHorizontalDragEnd: (details) {
                                // Swipe left to cancel
                                if (details.primaryVelocity! < 0) {
                                  _cancelListening();
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _isMicPressed
                                      ? Colors.grey[300] // Light gray when pressed
                                      : buttonColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.mic,
                                  color: _isMicPressed
                                      ? Colors.grey[600] // Darker gray for icon
                                      : Colors.white,
                                ),
                              ),
                            ),
                          // Show send button only when text field is not empty
                          if (_controller.text.isNotEmpty)
                            GestureDetector(
                              onTapDown: (_) {
                                setState(() {
                                  _isSendPressed = true;
                                });
                              },
                              onTapUp: (_) {
                                setState(() {
                                  _isSendPressed = false;
                                });
                                if (_controller.text.isNotEmpty) {
                                  query(_controller.text);
                                }
                              },
                              onTapCancel: () {
                                setState(() {
                                  _isSendPressed = false;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _isSendPressed
                                      ? Colors.grey[300] // Light gray when pressed
                                      : buttonColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.send,
                                  color: _isSendPressed
                                      ? Colors.grey[600] // Darker gray for icon
                                      : Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}