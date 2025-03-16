import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:surwa/data/models/profile.dart';

class ProfileCompletionNotifier extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isProfileComplete = false;
  bool get isProfileComplete => _isProfileComplete;

  /// Check if the user has a profile in Firestore
  Future<void> checkProfileCompletion() async {
    User? user = _auth.currentUser;
    if (user == null) {
      _isProfileComplete = false;
      notifyListeners();
      return;
    }

    DocumentSnapshot profileSnapshot = await _firestore.collection('profiles').doc(user.uid).get();

    if (profileSnapshot.exists) {
      _isProfileComplete = true;
    } else {
      _isProfileComplete = false;
    }
    notifyListeners();
  }

  /// Save a new profile to Firestore
  Future<void> saveProfile(Profile profile) async {
    await _firestore.collection('profiles').doc(profile.userId).set(profile.toMap());
    _isProfileComplete = true;
    notifyListeners();
  }
}
