import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to login screen after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFD62C), // Yellow background from logo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use Image.asset for the logo
            Image.asset(
              'assets/images/surwa_logo.png', // Make sure to add this image to your assets
              width: 350, // Adjust width as needed
              height: 250, // Adjust height as needed
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// pubspec.yaml configuration (add this under assets section)
// assets:
//   - assets/images/surwa_logo.png