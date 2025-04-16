import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_screen.dart'; // Import your login screen

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String? _emailError;
  String? _usernameError;
  String? _passwordError;
  String? _dobError;
  String? _regionError;
  String? _firstNameError;
  String? _lastNameError;
  String? _selectedRegion;

  final List<String> _regions = [
    'US',
    'Japan',
    'UK',
    'India',
    'Africa',
    'Australia',
  ];

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool isValidPassword(String password) {
    return password.length >= 8;
  }

  bool isValidDOB(String dob) {
    return dob.isNotEmpty;
  }

  bool isValidName(String name) {
    return name.isNotEmpty;
  }

  Future<void> _signup() async {
    setState(() {
      _emailError = null;
      _usernameError = null;
      _passwordError = null;
      _dobError = null;
      _regionError = null;
      _firstNameError = null;
      _lastNameError = null;
    });

    if (_emailController.text.isEmpty || !isValidEmail(_emailController.text)) {
      setState(() {
        _emailError = 'Please enter a valid email address';
      });
      return;
    }

    if (_usernameController.text.isEmpty) {
      setState(() {
        _usernameError = 'Please enter a username';
      });
      return;
    }

    if (_passwordController.text.isEmpty ||
        !isValidPassword(_passwordController.text)) {
      setState(() {
        _passwordError = 'Password must be at least 8 characters';
      });
      return;
    }

    if (_dobController.text.isEmpty || !isValidDOB(_dobController.text)) {
      setState(() {
        _dobError = 'Please select a date of birth';
      });
      return;
    }

    if (_firstNameController.text.isEmpty ||
        !isValidName(_firstNameController.text)) {
      setState(() {
        _firstNameError = 'Please enter your first name';
      });
      return;
    }

    if (_lastNameController.text.isEmpty ||
        !isValidName(_lastNameController.text)) {
      setState(() {
        _lastNameError = 'Please enter your last name';
      });
      return;
    }

    if (_selectedRegion == null) {
      setState(() {
        _regionError = 'Please select a region';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/api/signup/"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
          'username': _usernameController.text,
          'password': _passwordController.text,
          'dob': _dobController.text,
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'region': _selectedRegion,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String accessToken = responseData['access'];
        final String refreshToken = responseData['refresh'];

        await _storage.write(key: 'access_token', value: accessToken);
        await _storage.write(key: 'refresh_token', value: refreshToken);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Signup failed. Please try again.';
        if (!mounted) return;
        _showErrorDialog('Signup Failed', errorMessage);
      }
    } catch (e) {
      print('Error during signup: $e');
      if (!mounted) return;
      _showErrorDialog('Error', 'Failed to connect to the server');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: _emailError,
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  setState(() {
                    _emailError =
                        isValidEmail(value) ? null : 'Invalid email format';
                  });
                },
              ),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  errorText: _usernameError,
                ),
                onChanged: (value) {
                  setState(() {
                    _usernameError =
                        value.isEmpty ? 'Username cannot be empty' : null;
                  });
                },
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: _passwordError,
                ),
                obscureText: true,
                onChanged: (value) {
                  setState(() {
                    _passwordError =
                        isValidPassword(value)
                            ? null
                            : 'Password must be at least 8 characters';
                  });
                },
              ),
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  errorText: _firstNameError,
                ),
              ),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  errorText: _lastNameError,
                ),
              ),
              TextField(
                controller: _dobController,
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  errorText: _dobError,
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                decoration: InputDecoration(
                  labelText: 'Select Region',
                  errorText: _regionError,
                ),
                items:
                    _regions.map((String region) {
                      return DropdownMenuItem<String>(
                        value: region,
                        child: Text(region),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRegion = value;
                    _regionError = null;
                  });
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _signup,
                    child: const Text('Sign Up'),
                  ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
