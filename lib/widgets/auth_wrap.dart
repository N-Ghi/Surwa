import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surwa/data/notifiers/profile_completion_notifier.dart';
import 'package:surwa/screens/test_screens/create_user.dart';
import 'package:surwa/screens/test_screens/dashboard.dart';
import 'package:surwa/screens/test_screens/welcome_page.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      // User not logged in, show login screen
      print("User not logged in");
      return WelcomePage();
    } else {
      // User logged in, check both profile completion and database existence
      return Consumer<ProfileCompletionNotifier>(
        builder: (context, profileNotifier, _) {
          // Check if we need to load the profile data
          if (!profileNotifier.hasCheckedProfile) {
            // Trigger the check only once
            WidgetsBinding.instance.addPostFrameCallback((_) {
              profileNotifier.checkProfileCompletion(onUserNotFound: () {
                // User document doesn't exist in database, sign them out
                print("User document doesn't exist in database");
                FirebaseAuth.instance.signOut();
              });
            });
            
            print("Checking profile completion...");
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
          
          print("Profile completion checked");
          return profileNotifier.isProfileComplete ? HomeScreen() : ProfileTestScreen();
        },
      );
    }
  }
}