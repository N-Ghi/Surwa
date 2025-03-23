  import 'dart:io';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart' as auth;
  import 'package:firebase_storage/firebase_storage.dart';
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
        profilePictureUrl = await imagePickerService.uploadProfileImage( imageFile, currentUser!.uid);
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

      // Save profile details in Firestore using the userId as document ID
      await profileCollection.doc(currentUser!.uid).set(updatedProfile.toMap());
      
      // Create a mapping between Firebase Auth UID and username
      await userMapCollection.doc(profile.username).set({
        'userId': currentUser!.uid,
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
      
      // Get the profile document using userId
      DocumentSnapshot profileDoc = await profileCollection.doc(userId).get();
      if (profileDoc.exists && profileDoc.data() is Map<String, dynamic>) {
        Map<String, dynamic> data = profileDoc.data() as Map<String, dynamic>;
        return data['username'] as String?;
      }
      return null;
    } catch (e) {
      print("Error getting username: $e");
      return null;
    }
  }

  // Get userId from username
  Future<String?> getUserIdFromUsername(String username) async {
    try {
      QuerySnapshot query = await profileCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        Map<String, dynamic> data = query.docs.first.data() as Map<String, dynamic>;
        return data['userId'] as String?;
      }
      return null;
    } catch (e) {
      print("Error getting userId from username: $e");
      return null;
    }
  }

  // Get username from userId
  Future<String?> getUsernameFromUserId(String userId) async {
    try {
      DocumentSnapshot doc = await profileCollection.doc(userId).get();
      if (doc.exists && doc.data() is Map<String, dynamic>) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['username'] as String?;
      }
      return null;
    } catch (e) {
      print("Error getting username from userId: $e");
      return null;
    }
  }
  
  // Get the logged-in user's profile
  Future<Profile?> getLoggedInUserProfile() async {
    try {
      if (currentUser == null) return null;
      
      String userId = currentUser!.uid;
      DocumentSnapshot doc = await profileCollection.doc(userId).get();
      
      if (doc.exists) {
        return Profile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error retrieving profile: $e");
      return null;
    }
  }

  // Stream the logged-in user's profile
  Stream<Profile?> streamLoggedInUserProfile() {
    if (currentUser == null) {
      return Stream.value(null);
    }

    String userId = currentUser!.uid;
    return profileCollection.doc(userId).snapshots().map((doc) {
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

      String userId = currentUser!.uid;
      DocumentSnapshot doc = await profileCollection.doc(userId).get();
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
    File? newProfileImage,
    String? newPassword,
    required String currentPassword
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('User is not logged in');
      }

      String userId = currentUser!.uid;

      // Get current profile
      Profile? currentProfile = await getLoggedInUserProfile();
      if (currentProfile == null) {
        throw Exception('Profile not found');
      }

      String oldUsername = currentProfile.username;
      String oldEmail = currentUser!.email ?? '';
      String oldName = currentProfile.name;

      Map<String, dynamic> profileUpdates = {};

      // Handle name update
      if (name != null && name.isNotEmpty && name != oldName) {
        profileUpdates['name'] = name;
      }

      // Handle username update (use Firestore transaction)
      if (username != null && username.isNotEmpty && username != oldUsername) {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          QuerySnapshot usernameCheck = await userMapCollection
              .where('username', isEqualTo: username)
              .get();

          if (usernameCheck.docs.isNotEmpty) {
            throw Exception('Username already taken');
          }

          // Ensure atomicity: add new username, delete old mapping, and update profile
          transaction.set(userMapCollection.doc(username), {
            'userId': userId,
            'createdAt': FieldValue.serverTimestamp(),
          });

          transaction.delete(userMapCollection.doc(oldUsername));

          profileUpdates['username'] = username;
        });
      }

      // Handle profile picture update
      if (newProfileImage != null) {
        try {
          String? profilePictureUrl = await imagePickerService.uploadProfileImage(
            newProfileImage, currentUser!.uid);

          if (profilePictureUrl != null) {
            profileUpdates['profilePicture'] = profilePictureUrl;
          } else {
            throw Exception('Failed to upload profile picture');
          }
        } catch (e) {
          print('Profile picture update failed: $e');
          return 'Error uploading profile picture: ${e.toString()}';
        }
      }

      // Handle email update (requires verification)
      if (email != null && email.isNotEmpty && email != oldEmail) {
        try {
          await currentUser!.verifyBeforeUpdateEmail(email);
          
          // Mark email as pending verification in Firestore
          profileUpdates['emailPendingVerification'] = true;
          
          return 'Verification email sent. Please verify your new email address.';
        } catch (e) {
          print('Email update failed: $e');
          return 'Error updating email: ${e.toString()}';
        }
      }

      // Handle password update (requires reauthentication)
      if (newPassword != null && newPassword.isNotEmpty) {
        try {
          auth.AuthCredential credential = auth.EmailAuthProvider.credential(
            email: currentUser!.email!, 
            password: currentPassword,
          );

          await currentUser!.reauthenticateWithCredential(credential);
          await currentUser!.updatePassword(newPassword);
        } catch (e) {
          if (e is auth.FirebaseAuthException && e.code == 'wrong-password') {
            return 'Incorrect current password. Please try again.';
          }
          print('Password update failed: $e');
          return 'Error updating password: ${e.toString()}';
        }
      }

      // Finalize profile update if there are changes
      if (profileUpdates.isNotEmpty) {
        await profileCollection.doc(userId).update(profileUpdates);
      }

      print("Profile updated successfully!");

      return null; // Success, no error message needed
    } catch (e) {
      print("Error updating profile: $e");
      return 'Error: ${e.toString()}';
    }
  }

  // Delete the current user's profile and all associated data
  Future<String?> deleteProfile() async {
    try {
      if (currentUser == null) {
        throw Exception('User is not logged in');
      }

      String userId = currentUser!.uid;
      
      // Get the current profile
      Profile? profile = await getLoggedInUserProfile();
      if (profile == null) {
        throw Exception('Profile not found');
      }

      // Delete the profile from Firestore
      await profileCollection.doc(userId).delete();

      // Delete the username mapping from UserMap collection
      await userMapCollection.doc(profile.username).delete();

      // Delete the profile picture from Storage if it exists
      if (profile.profilePicture!.isNotEmpty) {
        try {
          // Get the file reference from the URL
          String fileUrl = profile.profilePicture!;
          await FirebaseStorage.instance.refFromURL(fileUrl).delete();
        } catch (e) {
          print("Warning: Could not delete profile picture: $e");
        }
        
        // Delete from Supabase if applicable
        try {
          final supabaseClient = Supabase.instance.client;
          final storage = supabaseClient.storage.from('profile-images');
          
          // Extract file path from URL if using Supabase
          Uri uri = Uri.parse(profile.profilePicture!);
          String filePath = uri.pathSegments.last;
          
          // Delete the file from Supabase Storage
          await storage.remove([filePath]);
        } catch (e) {
          print("Warning: Could not delete from Supabase: $e");
        }
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
      QuerySnapshot query = await userMapCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        String userId = query.docs.first['userId'] as String;
        DocumentSnapshot doc = await profileCollection.doc(userId).get();
        
        if (doc.exists) {
          return Profile.fromMap(doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      print("Error getting profile by username: $e");
      return null;
    }
  }


  // Search for users by username prefix
  Future<List<Profile>> searchUsersByUsername(String searchQuery, {int limit = 20}) async {
    try {
      if (searchQuery.isEmpty) {
        return [];
      }
      
      // Query Firestore for usernames containing the search string
      final querySnapshot = await profileCollection
          .where('username', isGreaterThanOrEqualTo: searchQuery)
          .where('username', isLessThanOrEqualTo: searchQuery + '\uf8ff') // Unicode character for range queries
          .limit(limit)
          .get();

      // Convert documents to Profile objects
      return querySnapshot.docs
          .map((doc) => Profile.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error searching users: $e");
      return [];
    }
  }

  // Get multiple profiles by usernames (batch fetch)
  Future<List<Profile>> getProfilesByUsernames(List<String> usernames) async {
    try {
      if (usernames.isEmpty) {
        return [];
      }
      
      List<Profile> profiles = [];
      
      // Firebase limitations prevent using 'whereIn' with large arrays,
      // so we'll use batched queries
      for (int i = 0; i < usernames.length; i += 10) {
        int end = (i + 10 < usernames.length) ? i + 10 : usernames.length;
        List<String> batch = usernames.sublist(i, end);
        
        QuerySnapshot querySnapshot = await profileCollection
            .where('username', whereIn: batch)
            .get();
        
        profiles.addAll(querySnapshot.docs
            .map((doc) => Profile.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
      }
      
      return profiles;
    } catch (e) {
      print("Error getting profiles by usernames: $e");
      return [];
    }
  }

  // Check if a user can view another user's profile (for privacy settings)
  Future<bool> canViewProfile(String targetUserId) async {
    try {
      // If the user is viewing their own profile, always allow
      if (currentUser?.uid == targetUserId) {
        return true;
      }
      
      // Get the target user's profile to check privacy settings
      DocumentSnapshot doc = await profileCollection.doc(targetUserId).get();
      
      if (!doc.exists) {
        return false; // Profile doesn't exist
      }
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      // Check for privacy settings (if implemented)
      // This is just an example - modify based on your privacy model
      bool isPrivate = data['isPrivate'] ?? false;
      
      if (!isPrivate) {
        return true; // Public profile can be viewed by anyone
      }
      
      // For private profiles, check if the current user is a follower
      List<dynamic> followers = data['followers'] ?? [];
      return followers.contains(currentUser?.uid);
    } catch (e) {
      print("Error checking profile visibility: $e");
      return false;
    }
  }
}