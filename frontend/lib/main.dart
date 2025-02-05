import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';
import 'screens/LoginScreen.dart'; // Import LoginScreen
import 'screens/SignupScreen.dart'; // Import SignupScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Chat App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/chat', // Set initial route to login screen
      routes: {
        '/chat': (context) => ChatScreen(),  // Chat Screen route
      },
    );
  }
}
