import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surwa/data/notifiers/profile_completion_notifier.dart';
import 'package:surwa/screens/complete_profile.dart';
import 'package:surwa/screens/feeds.dart';
import 'package:surwa/screens/login.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      // User not logged in, show login screen
      print("User not logged in");
      return LoginScreen();
    } else {
      // User logged in, check profile completion from SharedPreferences first
      return Consumer<ProfileCompletionNotifier>(
        builder: (context, profileNotifier, _) {
          // Initialize from shared preferences if not done already
          if (!profileNotifier.hasCheckedProfile) {
            // Trigger the initialization only once
            WidgetsBinding.instance.addPostFrameCallback((_) {
              profileNotifier.initialize();
            });
            
            print("Loading profile info...");
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text("Loading profile..."),
                  ],
                ),
              ),
            );
          }
          
          print("Profile check complete: ${profileNotifier.isProfileComplete}");
          return profileNotifier.isProfileComplete ? DashboardScreen() : CompleteProfile();
        },
      );
    }
  }
}