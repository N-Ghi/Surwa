import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surwa/data/models/profile.dart';
import 'package:surwa/services/profile_service.dart';

class ProfileCompletionNotifier extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  bool _isProfileComplete = false;
  bool _hasCheckedProfile = false;
  
  bool get isProfileComplete => _isProfileComplete;
  bool get hasCheckedProfile => _hasCheckedProfile;

  // Preference key for storing profile completion status
  static const String _profileCompletionKey = 'profile_completion_status';

  // Load the saved preference during initialization
  Future<void> initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _hasCheckedProfile = true;
      notifyListeners();
      return;
    }

    // User-specific key to handle multiple accounts
    final String userSpecificKey = '${_profileCompletionKey}_${user.uid}';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      // Check if we have a stored value
      if (prefs.containsKey(userSpecificKey)) {
        _isProfileComplete = prefs.getBool(userSpecificKey) ?? false;
        _hasCheckedProfile = true;
        notifyListeners();
        return;
      }
      
      // If no stored value, check from database
      await checkProfileCompletion();
    } catch (e) {
      print("Error initializing profile completion status: $e");
      _hasCheckedProfile = true;
      notifyListeners();
    }
  }

  Future<void> checkProfileCompletion({Function? onUserNotFound}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isProfileComplete = false;
      _hasCheckedProfile = true;
      notifyListeners();
      return;
    }

    // User-specific key
    final String userSpecificKey = '${_profileCompletionKey}_${user.uid}';

    try {
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

      // Check profile completion based on your criteria
      _isProfileComplete = profile.name.isNotEmpty && 
                          profile.username.isNotEmpty && 
                          profile.role.isNotEmpty;
      
      // Save the result to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(userSpecificKey, _isProfileComplete);
      
    } catch (e) {
      print("Error checking profile completion: $e");
      _isProfileComplete = false;
    }

    _hasCheckedProfile = true;
    notifyListeners();
  }

  // For direct use from CompleteProfile screen
  void setProfileCompletion(bool isComplete) async {
    _isProfileComplete = isComplete;
    _hasCheckedProfile = true;
    
    // Save to SharedPreferences
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String userSpecificKey = '${_profileCompletionKey}_${user.uid}';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(userSpecificKey, isComplete);
    }
    
    notifyListeners();
  }

  // Method to clear saved preferences (useful when signing out)
  Future<void> clearSavedStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final String userSpecificKey = '${_profileCompletionKey}_${user.uid}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userSpecificKey);
    
    // Reset local state
    _isProfileComplete = false;
    _hasCheckedProfile = false;
  }
}