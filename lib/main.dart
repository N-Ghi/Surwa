import 'package:flutter/material.dart';
import 'screens/test_screens/profile.dart' as test_profile;
import 'splash.dart';
import 'login.dart' as login;
import 'register.dart' as register;
import 'forgot_password.dart';
import 'profile.dart';
import 'market.dart';

void main() {
  runApp(const SurwaApp());
}

class SurwaApp extends StatelessWidget {
  const SurwaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Surwa App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFFD62C), // Yellow
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD62C),
          primary: const Color(0xFFFFD62C),
          secondary: const Color(0xFF009688), // Green for buttons
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF009688),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const login.LoginScreen(),
        '/register': (context) => const register.RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/market': (context) => MarketScreen(),
      },
    );
  }
}