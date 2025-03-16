import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:surwa/data/models/profile.dart';

class ProfileCompletionNotifier extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isProfileComplete = false;
  bool get isProfileComplete => _isProfileComplete;
  
  // Add a flag to track if we've checked the profile
  bool _hasCheckedProfile = false;
  bool get hasCheckedProfile => _hasCheckedProfile;

  /// Check if the user has a profile in Firestore
  Future<void> checkProfileCompletion() async {
    // Prevent multiple checks
    if (_hasCheckedProfile) return;
    
    User? user = _auth.currentUser;
    if (user == null) {
      _isProfileComplete = false;
      _hasCheckedProfile = true;
      print('User is not logged in.');
      notifyListeners();
      return;
    }

    try {
      // Note: Fix the collection name casing - 'Profiles' vs 'profiles'
      DocumentSnapshot profileSnapshot = await _firestore.collection('Profiles').doc(user.uid).get();

      if (profileSnapshot.exists) {
        _isProfileComplete = true;
        print('Profile exists for user: ${user.uid}');
      } else {
        _isProfileComplete = false;
        print('Profile does not exist for user: ${user.uid}');
      }
    } catch (e) {
      print('Error checking profile: $e');
      _isProfileComplete = false;
    }
    
    // Mark that we've completed the check
    _hasCheckedProfile = true;
    notifyListeners();
  }

  /// Save a new profile to Firestore
  Future<void> saveProfile(Profile profile) async {
    // Make sure we use the same collection name as in the check method
    await _firestore.collection('Profiles').doc(profile.userId).set(profile.toMap());
    _isProfileComplete = true;
    _hasCheckedProfile = true;
    print('Profile saved for user: ${profile.userId}');
    notifyListeners();
  }
  
  // Add a method to reset the state when needed (e.g., on logout)
  void reset() {
    _isProfileComplete = false;
    _hasCheckedProfile = false;
    notifyListeners();
  }
}