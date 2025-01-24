import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/'; // Replace with your Django API URL
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Login API request
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storage.write(key: 'access_token', value: data['access']);
      return {'status': true, 'message': 'Login successful'};
    } else {
      // Debugging: Log the response body for further analysis
      print("Login failed: ${response.body}");
      return {'status': false, 'message': 'Invalid credentials'};
    }
  }

  // Signup API request (with first_name, last_name, and email)
  Future<Map<String, dynamic>> signup(
    String username, 
    String firstName, 
    String lastName, 
    String email, 
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        return {'status': true, 'message': 'Signup successful'};
      } else {
        final responseBody = jsonDecode(response.body);
        String errorMessage = responseBody['error'] ?? 'Signup failed';
        return {'status': false, 'message': errorMessage};
      }
    } catch (e) {
      print("Error during signup: $e");
      return {'status': false, 'message': 'Error: $e'};
    }
  }

  // Send message API request
  Future<Map<String, dynamic>> sendMessage(String receiver, String message) async {
    final token = await _storage.read(key: 'access_token');
    
    final response = await http.post(
      Uri.parse('$baseUrl/messages/send/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'receiver': receiver, 'message': message}),
    );

    if (response.statusCode == 200) {
      return {'status': true, 'message': 'Message sent'};
    } else {
      print("Send Message Failed: ${response.body}");
      return {'status': false, 'message': 'Failed to send message'};
    }
  }

  // Fetch conversations API request
  Future<List<dynamic>> getConversations() async {
    final token = await _storage.read(key: 'access_token');
    
    final response = await http.get(
      Uri.parse('$baseUrl/messages/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      print("Fetch Conversations Failed: ${response.body}");
      return [];
    }
  }

  // Logout API request
  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }
}
