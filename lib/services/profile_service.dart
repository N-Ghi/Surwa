import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:surwa/services/image_picker_service.dart';
import 'package:surwa/data/models/profile.dart'; 

class ProfileService {
  
  final CollectionReference profileCollection = FirebaseFirestore.instance.collection('Profile');
  final CollectionReference userMapCollection = FirebaseFirestore.instance.collection('UserMap');
  final ImagePickerService imagePickerService = ImagePickerService();

  // Get current logged-in user

  auth.User? get currentUser => auth.FirebaseAuth.instance.currentUser;

  // Create a new profile
  Future<String?> createProfile(Profile profile, {File? imageFile}) async {
    try {
      // Check if the user is logged in
      if (currentUser == null) {
        throw Exception('User is not logged in');
      }

      // Validate username
      if (profile.username.isEmpty) {
        return 'Username cannot be empty';
      }

      // Check if username already exists
      QuerySnapshot usernameCheck = await profileCollection
          .where('username', isEqualTo: profile.username)
          .get();
      
      if (usernameCheck.docs.isNotEmpty) {
        return 'Username already taken';
      }

      String? profilePictureUrl;

      // Upload image if provided
      if (imageFile != null) {
        profilePictureUrl = await imagePickerService.uploadProfileImage(
            imageFile, profile.username);
        print("Profile picture URL: $profilePictureUrl");
      }

      // Update profile object with image URL and current user ID
      Profile updatedProfile = Profile(
        userId: currentUser!.uid, // Store the Firebase Auth UID
        username: profile.username,
        name: profile.name,
        profilePicture: profilePictureUrl ?? '',
        role: profile.role,
        followers: profile.followers,
        following: profile.following,
      );

      // Save profile details in Firestore using username as document ID
      await profileCollection.doc(profile.username).set(updatedProfile.toMap());
      
      // Create a mapping between Firebase Auth UID and username
      await userMapCollection.doc(currentUser!.uid).set({
        'username': profile.username,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("Profile created successfully!");
      return null;  // Success, no error message
    } catch (e) {
      print("Error creating profile: $e");
      return 'Error: ${e.toString()}';  // Return error message
    }
  }
  
  // Get username for the current user
  Future<String?> getCurrentUsername() async {
    try {
      String? userId = currentUser?.uid;
      if (userId == null) return null;
      
      DocumentSnapshot mapDoc = await userMapCollection.doc(userId).get();
      if (mapDoc.exists && mapDoc.data() is Map<String, dynamic>) {
        Map<String, dynamic> data = mapDoc.data() as Map<String, dynamic>;
        return data['username'] as String?;
      }
      return null;
    } catch (e) {
      print("Error getting username: $e");
      return null;
    }
  }
  
  // Get the logged-in user's profile
  Future<Profile?> getLoggedInUserProfile() async {
    try {
      // First get the username associated with the current auth user
      String? username = await getCurrentUsername();
      
      if (username != null) {
        DocumentSnapshot doc = await profileCollection.doc(username).get();
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

  // Stream the logged-in user's profile
  Stream<Profile?> streamLoggedInUserProfile() async* {
    // First get the username associated with the current auth user
    String? username = await getCurrentUsername();
    
    if (username == null) {
      yield null;
      return;
    }

    yield* profileCollection.doc(username).snapshots().map((doc) {
      if (doc.exists) {
        return Profile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Check if the user has a profile
  Future<bool> hasProfile() async {
    try {
      if (currentUser == null) {
        return false; // User is not logged in
      }

      String? username = await getCurrentUsername();
      if (username == null) {
        return false;
      }

      DocumentSnapshot doc = await profileCollection.doc(username).get();
      return doc.exists; // Return true if profile exists
    } catch (e) {
      print("Error checking profile: $e");
      return false;
    }
  }

  // Update an existing profile with enhanced functionality
  Future<String?> updateProfile({
    String? name,
    String? username,
    String? email,
    String? password,
    File? newProfileImage
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('User is not logged in');
      }
      
      // Get current profile for reference
      Profile? currentProfile = await getLoggedInUserProfile();
      if (currentProfile == null) {
        throw Exception('Profile not found');
      }
      
      // Get current username
      String oldUsername = currentProfile.username;
      
      // Update data map for Firestore
      Map<String, dynamic> profileUpdates = {};
      
      // Handle name update
      if (name != null && name.isNotEmpty) {
        profileUpdates['name'] = name;
      }
      
      // Handle username update (requires special handling for storage paths)
      if (username != null && username.isNotEmpty && username != oldUsername) {
        // Check if username is already taken
        QuerySnapshot usernameCheck = await profileCollection
            .where('username', isEqualTo: username)
            .get();
        
        if (usernameCheck.docs.isNotEmpty) {
          return 'Username already taken';
        }
        
        profileUpdates['username'] = username;
      }
      
      // Handle profile picture update
      if (newProfileImage != null) {
        // Use current username for storage path to ensure consistency
        String? profilePictureUrl = await imagePickerService.uploadProfileImage(
            newProfileImage, oldUsername);
        
        if (profilePictureUrl != null) {
          profileUpdates['profilePicture'] = profilePictureUrl;
        }
      }
      
      // Update email and password in Firebase Auth (if provided)
      if (email != null && email.isNotEmpty) {
        await currentUser!.verifyBeforeUpdateEmail(email);
        // Note: Email won't be updated until verified by the user
      }
      
      if (password != null && password.isNotEmpty) {
        await currentUser!.updatePassword(password);
      }
      
      // Update profile in Firestore if there are changes
      if (profileUpdates.isNotEmpty) {
        await profileCollection.doc(oldUsername).update(profileUpdates);
        
        // If username is being updated, we need special handling
        if (username != null && username.isNotEmpty && username != oldUsername) {
          // Get the updated profile data
          DocumentSnapshot oldProfileDoc = await profileCollection.doc(oldUsername).get();
          if (!oldProfileDoc.exists) {
            throw Exception('Profile not found after update');
          }
          
          // Create a new document with the new username
          await profileCollection.doc(username).set(oldProfileDoc.data() as Map<String, dynamic>);
          
          // Update the username mapping in UserMap collection
          await userMapCollection.doc(currentUser!.uid).update({
            'username': username
          });
          
          // Update storage references (for profile pictures, posts, etc.)
          await _updateStorageReferences(oldUsername, username);
          
          // Delete the old profile document
          await profileCollection.doc(oldUsername).delete();
        }
      }
      
      print("Profile updated successfully!");
      
      // Return appropriate message based on email update
      if (email != null && email.isNotEmpty) {
        return 'Verification email sent. Please verify your new email address.';
      }
      return null; // Success, no message needed
    } catch (e) {
      print("Error updating profile: $e");
      return 'Error: ${e.toString()}';
    }
  }

  // Helper method to update storage references when username changes
  Future<void> _updateStorageReferences(String oldUsername, String newUsername) async {
    try {
      // Initialize Firebase Storage instance
      final storage = FirebaseStorage.instance;
      
      // Update profile images in storage
      // 1. List all files under the old username path in Profile bucket
      final profileRef = storage.ref('Profile/$oldUsername');
      
      try {
        final listResult = await profileRef.listAll();
        
        // 2. Copy each file to the new path
        for (var item in listResult.items) {
          // Get the file name without the path
          final fileName = item.name;
          
          // Download the file data
          final data = await item.getData();
          
          if (data != null) {
            // Create reference to new location
            final newRef = storage.ref('Profile/$newUsername/$fileName');
            
            // Upload to new location
            await newRef.putData(data);
            
            // Update the URL in Firestore if this is the profile picture
            DocumentSnapshot profileDoc = await profileCollection.doc(newUsername).get();
            if (profileDoc.exists) {
              Map<String, dynamic> profileData = profileDoc.data() as Map<String, dynamic>;
              
              // Check if this file is the current profile picture
              String currentPicUrl = profileData['profilePicture'] ?? '';
              if (currentPicUrl.contains('/$oldUsername/')) {
                // Update with new URL (replace old username with new username in the URL)
                String newPicUrl = currentPicUrl.replaceAll('/$oldUsername/', '/$newUsername/');
                await profileCollection.doc(newUsername).update({
                  'profilePicture': newPicUrl
                });
              }
            }
            
            // Delete the old file
            await item.delete();
          }
        }
        
        // Try to delete the old directory after all files are moved
        try {
          await profileRef.delete();
        } catch (e) {
          // Ignore errors when deleting directory - Firebase may not support direct directory deletion
          print("Note: Directory deletion may not be supported: $e");
        }
      } catch (e) {
        // Handle case where there might be no files
        print("No files found or error in Profile/$oldUsername: $e");
      }
      
      // Also update posts storage references if needed
      final postsRef = storage.ref('Posts/$oldUsername');
      
      try {
        final postsListResult = await postsRef.listAll();
        
        // Process post files similarly
        for (var item in postsListResult.items) {
          final fileName = item.name;
          final data = await item.getData();
          
          if (data != null) {
            final newRef = storage.ref('Posts/$newUsername/$fileName');
            await newRef.putData(data);
            
            // Update URLs in posts collection if needed
            final postsCollection = FirebaseFirestore.instance.collection('Posts');
            QuerySnapshot postsQuery = await postsCollection
                .where('userId', isEqualTo: oldUsername)
                .get();
                
            for (var postDoc in postsQuery.docs) {
              // Update the username reference
              await postDoc.reference.update({
                'userId': newUsername
              });
              
              // Update image URL if applicable
              String currentUrl = postDoc['imageUrl'] ?? '';
              if (currentUrl.contains('/$oldUsername/')) {
                String newUrl = currentUrl.replaceAll('/$oldUsername/', '/$newUsername/');
                await postDoc.reference.update({
                  'imageUrl': newUrl
                });
              }
            }
            
            // Delete the old file
            await item.delete();
          }
        }
        
        // Try to delete the old directory
        try {
          await postsRef.delete();
        } catch (e) {
          print("Note: Directory deletion may not be supported: $e");
        }
      } catch (e) {
        print("No files found or error in Posts/$oldUsername: $e");
      }
      
      print("Storage references updated successfully from $oldUsername to $newUsername");
    } catch (e) {
      print("Error updating storage references: $e");
      throw e;
    }
  }

  // Delete the current user's profile and all associated data
  Future<String?> deleteProfile() async {
    try {
      if (currentUser == null) {
        throw Exception('User is not logged in');
      }

      // Get the current profile
      Profile? profile = await getLoggedInUserProfile();
      if (profile == null) {
        throw Exception('Profile not found');
      }

      // Delete the profile from Firestore
      await profileCollection.doc(profile.username).delete();

      // Delete the user mapping from UserMap collection
      await userMapCollection.doc(currentUser!.uid).delete();

      // Delete the profile picture from Supabase Storage if it exists
      if (profile.profilePicture!.isNotEmpty) {
        // Assuming you have a Supabase client instance
        final supabaseClient = Supabase.instance.client;
        final storage = supabaseClient.storage.from('profile-images');
        
        // Delete the file from Supabase Storage
        await storage.remove([profile.profilePicture!]);
      }

      print("Profile and associated data deleted successfully!");
      return null; // Success, no error message
    } catch (e) {
      print("Error deleting profile: $e");
      return 'Error: ${e.toString()}';
    }
  }

  // Get a user profile by username
  Future<Profile?> getProfileByUsername(String username) async {
    try {
      DocumentSnapshot doc = await profileCollection.doc(username).get();
      if (doc.exists) {
        return Profile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error retrieving profile by username: $e");
      return null;
    }
  }
}