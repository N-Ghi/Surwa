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
        _hasCheckedProfile = true;
        notifyListeners();
        
        if (onUserNotFound != null) {
          onUserNotFound(); // This will sign the user out
        }
        return;
      }

      // More comprehensive profile completion check
      _isProfileComplete = profile.name.isNotEmpty && 
                          profile.username.isNotEmpty && 
                          profile.role.isNotEmpty;
      
      print('Profile is complete: $_isProfileComplete');
    } catch (e) {
      print('Error checking profile: $e');
      _isProfileComplete = false;
    }

    _hasCheckedProfile = true;
    notifyListeners(); // Ensure this is called to trigger UI update
  }

  // Optional: Method to manually set profile completion status
  void setProfileCompletion(bool isComplete) {
    _isProfileComplete = isComplete;
    _hasCheckedProfile = true;
    notifyListeners();
  }
}