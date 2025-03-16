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
    final profileNotifier = Provider.of<ProfileCompletionNotifier>(context);

    if (user == null) {
      // User not logged in, show login screen
      return WelcomePage();
    } else {
      // User logged in, check profile completion
      return FutureBuilder(
        future: profileNotifier.checkProfileCompletion(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          } else {
            return profileNotifier.isProfileComplete ? HomeScreen() : CreateProfile();
          }
        },
      );
    }
  }
}
