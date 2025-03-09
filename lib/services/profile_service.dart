import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/services/image_picker_service.dart';

class UserService {
  final CollectionReference profile = FirebaseFirestore.instance.collection('profile');

  // Create a new profile
  Future<void> createProfile(String email, String name, File? imageFile, String role, List<String>? followers, List<String>? following) async {
  try {
    String? profilePictureUrl;

    // Upload image if selected
    if (imageFile != null) {
      profilePictureUrl = await uploadProfilePicture(imageFile, email);
    }

    // Save profile details in Firestore
    await FirebaseFirestore.instance.collection('profile').doc(email).set({
      'email': email,
      'name': name,
      'profilePicture': profilePictureUrl ?? '',
      'role': role,
      'followers': followers ?? [],
      'following': following ?? []
    });

    print("Profile created successfully!");
  } catch (e) {
    print("Error creating profile: $e");
  }
  }

  // Read an existing profile
  Stream<List<Map<String, dynamic>>> streamAllUsers() {
    return FirebaseFirestore.instance.collection('profile').snapshots().map((querySnapshot) {
      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  // Update an existing profile
  Future<void> updateUser(String email, Map<String, dynamic> updatedData) async {
  try {
    await FirebaseFirestore.instance.collection('profile').doc(email).update(updatedData);
    print("User updated successfully!");
  } catch (e) {
    print("Error updating user: $e");
  }
}

  // Delete an existing profile
  Future<void> deleteUser(String email) async {
  try {
    await FirebaseFirestore.instance.collection('profile').doc(email).delete();
    print("User deleted successfully!");
  } catch (e) {
    print("Error deleting user: $e");
  }
}

}