import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final String? accessToken = await _storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/api/userinfo/"),
        headers: {"Authorization": "Bearer $accessToken"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _usernameController.text = data['username'] ?? '';
          _emailController.text = data['email'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load user data (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final String? accessToken = await _storage.read(key: 'access_token');

      // Build the request body dynamically
      final Map<String, dynamic> updateData = {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      if (_passwordController.text.isNotEmpty) {
        updateData['password'] = _passwordController.text;
      }

      final response = await http.put(
        Uri.parse("http://10.0.2.2:8000/api/user/update/"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json"
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage = 'Failed to update profile (${response.statusCode}): ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating profile: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a username' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter an email' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'New Password (leave blank to keep current)',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 30),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _updateUser,
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
