import 'package:flutter/material.dart';
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

  // Function to fetch the user info from the backend (Django)
  Future<void> fetchUserInfo() async {
    try {
      final response = await http.get(
        Uri.parse(
            "http://localhost:8000/api/userinfo/"), // Your Django API endpoint
        headers: {
          "Authorization": "Bearer your_token_here"
        }, // Add your authentication token
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          username = data['username'] ?? "Unknown User"; // Set the username
        });
      }
    } catch (e) {
      setState(() {
        username = "Error fetching user"; // In case of error
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
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  @override
  Widget build(BuildContext context) {
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
                } else if (value == 'Toggle Dark Mode') {
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
                  value: 'Toggle Dark Mode',
                  child: Row(
                    children: [
                      Icon(Icons.dark_mode, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Toggle Dark Mode'),
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
                      TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          labelText: "Enter your prompt",
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              if (_controller.text.isNotEmpty) {
                                query(_controller.text);
                              }
                            },
                            icon: Icon(
                              Icons.send,
                              color: Colors.lightGreen,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
