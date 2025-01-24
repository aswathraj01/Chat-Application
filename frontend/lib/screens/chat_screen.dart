import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(MyApp());
}


class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light; // Default theme is light mode

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: ChatScreen(toggleTheme: _toggleTheme, themeMode: _themeMode),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  ChatScreen({required this.toggleTheme, required this.themeMode});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _messageController = TextEditingController();
  bool _isTyping = false; // Tracks if user is typing
  bool _isListening = false; // Tracks if speech recognition is listening
  String _speechText = ""; // Holds the recognized speech
  List<Message> _messages = []; // Holds chat messages
  stt.SpeechToText _speechToText = stt.SpeechToText(); // Speech-to-text object

  void _handleTextChange(String text) {
    setState(() {
      _isTyping = text.isNotEmpty;
    });
  }

  void _startListening() async {
    bool available = await _speechToText.initialize();
    if (available) {
      setState(() {
        _isListening = true;
      });
      _speechToText.listen(onResult: (result) {
        setState(() {
          _speechText = result.recognizedWords;
        });
      });
    }
  }

  void _stopListening() {
    _speechToText.stop();
    setState(() {
      _isListening = false;
      _messages.add(Message(text: _speechText, isUser: true)); // User's message
      _speechText = ""; // Reset speech text after adding to messages
    });
    // Simulate an AI response
    _simulateIncomingMessage();
  }

  void _simulateIncomingMessage() {
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _messages.add(Message(text: "test done", isUser: false)); // AI's response
      });
    });
  }

  void showAboutDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("About Ai Chat Application"),
          content: Text(
              "This application is built with Flutter. I am learning Flutter by building the user interface for the application."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Chat AI"),
        backgroundColor: Colors.teal,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Opens the drawer
              },
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 30.0),
            child: IconButton(
              icon: Icon(
                widget.themeMode == ThemeMode.light
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              onPressed: widget.toggleTheme, // Toggle theme button in AppBar
            ),
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.teal,
              ),
              child: Text(
                "Menu",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Settings"),
              onTap: () {
                // Handle Settings tap
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text("About"),
              onTap: () {
                Navigator.of(context).pop();
                showAboutDetails(context); // Handle About tap
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.brightness_6),
              title: Text("Toggle Dark Mode"),
              onTap: widget.toggleTheme, // Call the toggle theme function
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: _messages.length, // Use dynamic list length
              itemBuilder: (context, index) {
                Message message = _messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Colors.grey[300]
                          : Colors.teal[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom input area
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: Colors.grey[200],
            child: Row(
              children: [
                // Text input field
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: _handleTextChange,
                    decoration: InputDecoration(
                      hintText: "Type a message",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),

                SizedBox(width: 10),

                // Dynamic mic/send button
                IconButton(
                  icon: Icon(
                    _isTyping ? Icons.send : Icons.mic,
                    color: Colors.teal,
                  ),
                  onPressed: () {
                    if (_isTyping) {
                      // Handle send button press
                      setState(() {
                        _messages.add(Message(
                          text: _messageController.text,
                          isUser: true,
                        ));
                        _messageController.clear();
                        _handleTextChange(""); // Reset typing state
                      });
                      _simulateIncomingMessage(); // Simulate response
                    } else {
                      // Handle mic button press
                      if (!_isListening) {
                        _startListening();
                      } else {
                        _stopListening();
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final bool isUser; // True if message is from user, false if from AI

  Message({required this.text, required this.isUser});
}
