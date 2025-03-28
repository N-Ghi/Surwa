import 'package:flutter/material.dart';
import 'package:surwa/screens/complete_profile.dart';
import 'package:surwa/screens/forgot_password.dart';
import 'package:surwa/screens/register.dart';

import 'package:provider/provider.dart';
import 'package:surwa/data/notifiers/auth_notifier.dart';
import 'package:surwa/screens/test_screens/create_user.dart';
import 'package:surwa/data/notifiers/profile_completion_notifier.dart';
import 'package:surwa/screens/dashboard.dart';
import 'package:surwa/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
        print('Profile is complete. Navigating to Dashboard...'); // Debug message
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        print('Profile is not complete. Navigating to CompleteProfile...'); // Debug message
        // If the profile is not complete, redirect to Profile Completion Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CompleteProfile()),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFD62C),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/images/surwa_logo.png',
                    width: MediaQuery.of(context).size.width * 0.7, // Responsive width
                    height: 200, // Fixed height, but you can make this responsive too
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 40),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                _buildForgotPasswordRow(),
                const SizedBox(height: 40),
                _buildLoginButton(),
                const SizedBox(height: 20),
                _buildSignUpRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'E-mail',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: TextStyle(color: Colors.black54),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          style: TextStyle(color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.black54),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          style: TextStyle(color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Text(
            'Must contain 8 char.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPasswordScreen(),));
            },
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
      if (_errorMessage != null) ...[
        const SizedBox(height: 10),
        Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ],
    ],
  );
}

  Widget _buildSignUpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account?"),
        TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
          },
          child: const Text(
            'Sign Up',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}