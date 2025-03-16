import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthNotifier extends ChangeNotifier {
  User? _user;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthNotifier() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners(); // Notify UI of state changes
    });
  }

  User? get user => _user;
  bool get isLoggedIn => _user != null && _user!.emailVerified;

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
