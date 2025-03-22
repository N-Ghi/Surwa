import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surwa/data/notifiers/auth_notifier.dart';
import 'package:surwa/screens/test_screens/create_user.dart';
import 'package:surwa/data/notifiers/profile_completion_notifier.dart';
import 'package:surwa/screens/test_screens/dashboard.dart';
import 'package:surwa/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); // Fix the key parameter

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    final profileCompletionNotifier = Provider.of<ProfileCompletionNotifier>(context, listen: false);
    final authService = AuthService();  // Instantiate AuthService

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    print('Logging in...'); // Debug message

    // Call AuthService to sign in the user
    String? result = await authService.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      authNotifier,
      context,
    );

    setState(() {
      _isLoading = false;
      _errorMessage = result;
    });

    if (result == null) {
      print('Login successful!'); // Debug message

      // Check profile completion after successful login
      await profileCompletionNotifier.checkProfileCompletion();

      // Navigate to HomeScreen if the profile is complete
      if (profileCompletionNotifier.isProfileComplete) {
        print('Profile is complete. Navigating to HomeScreen...'); // Debug message
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        print('Profile is not complete. Navigating to ProfileTestScreen...'); // Debug message
        // If the profile is not complete, redirect to Profile Completion Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileTestScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: Text("Login"),
                    ),
              if (_errorMessage != null) ...[
                SizedBox(height: 10),
                Text(_errorMessage!, style: TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
