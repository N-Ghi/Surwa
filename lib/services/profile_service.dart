import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:surwa/services/image_picker_service.dart';
import 'package:surwa/data/models/profile.dart'; 

class ProfileService {
  final CollectionReference profileCollection =
      FirebaseFirestore.instance.collection('Profile');

  final ImagePickerService imagePickerService = ImagePickerService();

  // Get current logged-in user
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Create a new profile
  Future<String?> createProfile(Profile profile) async {
    try {
      // Check if the user is logged in
      if (currentUser == null) {
        throw Exception('User is not logged in');
      }

      String? profilePictureUrl;

      // Pick image from gallery
      File? imageFile = await imagePickerService.pickImage(ImageSource.gallery);

      // Upload image if selected
      if (imageFile != null) {
        profilePictureUrl = await imagePickerService.uploadProfileImage(imageFile, profile.username);
        print("Profile picture URL: $profilePictureUrl");
      }

      // Update profile object with image URL
      Profile updatedProfile = Profile(
        userId: currentUser!.uid, // Use logged-in user's UID
        username: profile.username,
        name: profile.name,
        profilePicture: profilePictureUrl ?? '',
        role: profile.role,
        followers: profile.followers,
        following: profile.following,
      );

      // Save profile details in Firestore
      await profileCollection.doc(currentUser!.uid).set(updatedProfile.toMap()); // Store by UID

      print("Profile created successfully!");
      return null;  // Success, no error message
    } catch (e) {
      print("Error creating profile: $e");
      return 'Error: ${e.toString()}';  // Return error message
    }
  }
  
  // Get the logged-in user's profile
  Future<Profile?> getLoggedInUserProfile() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        DocumentSnapshot doc = await profileCollection.doc(userId).get();
        if (doc.exists) {
          return Profile.fromMap(doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      print("Error retrieving profile: $e");
      return null;
    }
  }

  // Stream the logged-in user's profile (stream only the logged-in user's profile)
  Stream<Profile?> streamLoggedInUserProfile() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Stream.value(null);
    }

    return profileCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return Profile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Update an existing profile
  Future<void> updateProfile(Map<String, dynamic> updatedData) async {
    try {
      if (currentUser == null) {
        throw Exception('User is not logged in');
      }

      await profileCollection.doc(currentUser!.uid).update(updatedData); // Update by user ID
      print("Profile updated successfully!");
    } catch (e) {
      print("Error updating profile: $e");
    }
  }

  // Delete the current user's profile
  Future<void> deleteProfile() async {
    try {
      if (currentUser == null) {
        throw Exception('User is not logged in');
      }

      await profileCollection.doc(currentUser!.uid).delete(); // Delete by user ID
      print("Profile deleted successfully!");
    } catch (e) {
      print("Error deleting profile: $e");
    }
  }

  // Check if the user has a profile
  Future<bool> hasProfile() async {
    try {
      if (currentUser == null) {
        return false; // User is not logged in
      }

      DocumentSnapshot doc = await profileCollection.doc(currentUser!.uid).get();
      return doc.exists; // Return true if profile exists
    } catch (e) {
      print("Error checking profile: $e");
      return false;
    }
  }
}
