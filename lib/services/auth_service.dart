import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surwa/data/notifiers/auth_notifier.dart';
import 'package:surwa/data/notifiers/profile_completion_notifier.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<String?> signUpWithEmail(String email, String password, BuildContext context) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {

        // Send email verification
        await user.sendEmailVerification();

        // Notify the app that profile is complete
        Provider.of<ProfileCompletionNotifier>(context, listen: false).checkProfileCompletion();
      }
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return error message
    }
  }

  Future<String?> signInWithEmail(String email, String password, AuthNotifier authNotifier, BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!userCredential.user!.emailVerified) {
        return "Please verify your email before logging in.";
      }

      // Check if the user has a profile in Firestore
      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot profileSnapshot = await _firestore.collection('profiles').doc(user.uid).get();

        // If profile exists, notify ProfileCompletionNotifier
        if (profileSnapshot.exists) {
          // Profile is complete, notify the ProfileCompletionNotifier
          Provider.of<ProfileCompletionNotifier>(context, listen: false).checkProfileCompletion();
        } else {
          // Profile is not complete, handle accordingly
          Provider.of<ProfileCompletionNotifier>(context, listen: false).checkProfileCompletion();
        }
      }

      authNotifier.notifyListeners(); // Notify UI of login state
      return null; // Success
    } catch (e) {
      return e.toString(); // Return error message
    }
  }

  Future<void> signOut(AuthNotifier authNotifier) async {
    await _auth.signOut();
    authNotifier.notifyListeners(); // Notify UI
  }
}
