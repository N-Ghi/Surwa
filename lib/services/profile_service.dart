import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:surwa/services/image_picker_service.dart';
import 'package:surwa/data/models/profile.dart'; 

class ProfileService {
  
  final CollectionReference profileCollection =
      FirebaseFirestore.instance.collection('Profile');

  final ImagePickerService imagePickerService = ImagePickerService();

  // Create a new profile
  Future<void> createProfile(Profile profile) async {
    try {
      String? profilePictureUrl;

      // Pick image from gallery
      File? imageFile = await imagePickerService.pickImage(ImageSource.gallery);

      // Upload image if selected
      if (imageFile != null) {
        profilePictureUrl = await imagePickerService.uploadProfileImage(imageFile, '${profile.username}');
        print("Profile picture URL: $profilePictureUrl");
      }

      // Update profile object with image URL
      Profile updatedProfile = Profile(
        username: profile.username,
        name: profile.name,
        profilePicture: profilePictureUrl ?? '',
        role: profile.role,
        followers: profile.followers,
        following: profile.following,
      );

      // Save profile details in Firestore
      await profileCollection.doc(profile.username).set(updatedProfile.toMap());

      print("Profile created successfully!");
    } catch (e) {
      print("Error creating profile: $e");
    }
  }



  // Read an existing profile (stream all profiles)
  Stream<List<Profile>> streamAllProfiles() {
    return profileCollection.snapshots().map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => Profile.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get a single profile profile
  Future<Profile?> getProfile(String username) async {
    try {
      DocumentSnapshot doc = await profileCollection.doc(username).get();
      if (doc.exists) {
        return Profile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error retrieving profile: $e");
      return null;
    }
  }

  // Update an existing profile
  Future<void> updateProfile(String username, Map<String, dynamic> updatedData) async {
    try {
      await profileCollection.doc(username).update(updatedData);
      print("Profile updated successfully!");
    } catch (e) {
      print("Error updating profile: $e");
    }
  }

  // Delete an existing profile
  Future<void> deleteProfile(String username) async {
    try {
      await profileCollection.doc(username).delete();
      print("Profile deleted successfully!");
    } catch (e) {
      print("Error deleting profile: $e");
    }
  }
}
