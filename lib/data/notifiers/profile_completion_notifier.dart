import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:surwa/data/models/profile.dart';
import 'package:surwa/services/profile_service.dart';

class ProfileCompletionNotifier extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  bool _isProfileComplete = false;
  bool _hasCheckedProfile = false;
  bool get isProfileComplete => _isProfileComplete;
  bool get hasCheckedProfile => _hasCheckedProfile;

  Future<void> checkProfileCompletion({Function? onUserNotFound}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isProfileComplete = false;
      _hasCheckedProfile = true;
      notifyListeners();
      return;
    }

    try {
      print('Checking profile completion...');
      Profile? profile = await _profileService.getLoggedInUserProfile();
      if (profile == null) {
        _isProfileComplete = false;
        _hasCheckedProfile = true; // Ensure this is updated before triggering sign-out
        notifyListeners();
        if (onUserNotFound != null) {
          onUserNotFound(); // This will sign the user out
        }
        return;
      }

      _isProfileComplete = profile.name.isNotEmpty && profile.username.isNotEmpty;
      print('Profile is complete: $_isProfileComplete');
    } catch (e) {
      print('Error checking profile: $e');
      _isProfileComplete = false;
    }

    _hasCheckedProfile = true;
    notifyListeners();
  }
}