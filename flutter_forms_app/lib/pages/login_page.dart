import 'package:flutter/material.dart';
import '../widgets/login/email_field.dart';
import '../widgets/login/password_field.dart';
import '../widgets/login/remember_me_checkbox.dart';
import '../services/shared_preferences_service.dart';
import '../models/user_model.dart';
import 'profile_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() async {
    try {
      final userData = await SharedPreferencesService.getUserData();
      if (userData['rememberMe'] == true) {
        setState(() {
          _emailController.text = userData['email']?.toString() ?? '';
          _passwordController.text = userData['password']?.toString() ?? '';
          _rememberMe = true;
        });
      }
    } catch (e) {
      print('Error loading credentials: $e');
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      final user = User(
        email: _emailController.text,
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (_rememberMe) {
        await SharedPreferencesService.saveUserData(user.toJson());
      }

      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage(user: user)),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login berhasil!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EmailField(controller: _emailController),
              const SizedBox(height: 16),
              PasswordField(controller: _passwordController),
              const SizedBox(height: 16),
              RememberMeCheckbox(
                initialValue: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text('Login'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}