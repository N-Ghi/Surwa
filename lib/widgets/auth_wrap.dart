import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:surwa/data/notifiers/profile_completion_notifier.dart';
import 'package:surwa/screens/test%20screens/create_user.dart';
import 'package:surwa/screens/test%20screens/dashboard.dart';
import 'package:surwa/screens/test%20screens/welcome_page.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    print('User: $user');

    if (user == null) {
      // User not logged in, show login screen
      print('User not logged in');
      return WelcomePage();
    } else {
      // User logged in, check profile completion
      print('User logged in');
      
      // Use Consumer instead of Provider.of to avoid rebuilding the whole widget
      return Consumer<ProfileCompletionNotifier>(
        builder: (context, profileNotifier, _) {
          // Check if we need to load the profile data
          if (!profileNotifier.hasCheckedProfile) {
            // Trigger the check only once
            WidgetsBinding.instance.addPostFrameCallback((_) {
              profileNotifier.checkProfileCompletion();
            });
            
            // Show loading while checking
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text("Checking profile completion..."),
                  ],
                ),
              ),
            );
          }
          
          // Profile check completed, return appropriate screen
          return profileNotifier.isProfileComplete ? HomeScreen() : CreateProfile();
        },
      );
    }
  }
}