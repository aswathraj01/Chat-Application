import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screen/login_screen.dart';
import 'screen/signup_screen.dart';
import 'screen/chat_screen.dart';

void main() {
  runApp(const MyAppWrapper());
}

// Wrapper widget to handle permission in initState
class MyAppWrapper extends StatefulWidget {
  const MyAppWrapper({super.key});

  @override
  State<MyAppWrapper> createState() => _MyAppWrapperState();
}

class _MyAppWrapperState extends State<MyAppWrapper> {
  @override
  void initState() {
    super.initState();
    requestMicPermission();
  }

  Future<void> requestMicPermission() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      print('🎤 Microphone permission granted');
    } else if (status.isDenied) {
      print('❌ Microphone permission denied');
    } else if (status.isPermanentlyDenied) {
      print('⚠️ Microphone permission permanently denied. Ask user to enable it from settings.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MyApp();
  }
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/chat': (context) => ChatScreen(),
      },
    );
  }
}
