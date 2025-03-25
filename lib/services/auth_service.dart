import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as Supabase;
import 'package:surwa/data/notifiers/auth_notifier.dart';
import 'package:surwa/data/notifiers/profile_completion_notifier.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final supabase = Supabase.Supabase.instance.client;
  final List<String> bucketNames = ['user_uploads', 'profile-images'];

  Future<String?> signUpWithEmail(String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();
        Provider.of<ProfileCompletionNotifier>(context, listen: false).checkProfileCompletion();
      }
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return error message
    }
  }

  Future<String?> signInWithEmail(
      String email, String password, AuthNotifier authNotifier, BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) return "Authentication failed.";

      if (!user.emailVerified) {
        return "Please verify your email before logging in.";
      }

      // Check if the user profile exists in Firestore
      bool profileExists = (await _firestore.collection('profiles').doc(user.uid).get()).exists;

      // Notify ProfileCompletionNotifier accordingly
      Provider.of<ProfileCompletionNotifier>(context, listen: false).checkProfileCompletion();

      // Notify AuthNotifier of login state change
      authNotifier.notifyListeners();

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An unknown error occurred.";
    }
  }

  Future<void> signOut(AuthNotifier authNotifier) async {
    await _auth.signOut();
    authNotifier.notifyListeners(); // Notify UI
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<String?> updatePassword(String password) async {
    User? user = _auth.currentUser;
    if (user == null) return "No user signed in.";
    try {
      await user.updatePassword(password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> updateEmail(String email) async {
    User? user = _auth.currentUser;
    if (user == null) return "No user signed in.";
    try {
      await user.updateEmail(email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
  
  Future<String?> deleteAccount() async {
    User? user = _auth.currentUser;
    if (user == null) return "No user signed in.";

    try {
      String userId = user.uid;

      // Delete user profile from Firestore
      await _firestore.collection('Profile').doc(userId).delete();

      // Delete all user posts
      final postsCollection = _firestore.collection('Post').doc(userId).collection('posts');
      final postSnapshots = await postsCollection.get();
      for (var doc in postSnapshots.docs) {
        await doc.reference.delete();
      }

      // Delete all user comments
      final commentsCollection = _firestore.collection('Comment').doc(userId).collection('comments');
      final commentSnapshots = await commentsCollection.get();
      for (var doc in commentSnapshots.docs) {
        await doc.reference.delete();
      }

      // Delete user images from Supabase Storage
      for (String bucketName in bucketNames) {
      try {
        final List<Supabase.FileObject> response = await supabase.storage.from(bucketName).list(path: userId);
        if (response.isNotEmpty) {
          List<String> filePaths = response.map((file) => '$userId/${file.name}').toList();
          await supabase.storage.from(bucketName).remove(filePaths);
        }
      } catch (e) {
        print("Error deleting images from Supabase bucket $bucketName: $e");
      }
    }

      // Finally, delete the user from Firebase Authentication
      await user.delete();

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Failed to delete user account.";
    }
  }

}
