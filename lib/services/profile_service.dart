  import 'dart:io';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart' as auth;
  import 'package:firebase_storage/firebase_storage.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:surwa/services/image_picker_service.dart';
  import 'package:surwa/data/models/profile.dart'; 
  import 'package:shared_preferences/shared_preferences.dart';

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
      }

      // Update profile object with image URL and current user ID
      Profile updatedProfile = Profile(
        userId: currentUser!.uid, // Store the Firebase Auth UID
        username: profile.username,
        name: profile.name,
        lowercase_username: profile.username.toLowerCase(),
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

      return null;  // Success, no error message
    } catch (e) {
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
      return null;
    }
  }
  
  // Get the logged-in user's profile
  Future<Profile?> getLoggedInUserProfile() async {
    try {
      if (currentUser == null) return null;

      debugSharedPreferences();
      String userId = currentUser!.uid;
      DocumentSnapshot doc = await profileCollection.doc(userId).get();
      
      if (doc.exists) {
        return Profile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
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
      return false;
    }
  }

  // Update an existing profile with enhanced functionality
  Future<String?> updateProfile({
    String? name,
    String? username,
    File? newProfileImage,
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
          return 'Error uploading profile picture: ${e.toString()}';
        }
      }
      // Finalize profile update if there are changes
      if (profileUpdates.isNotEmpty) {
        await profileCollection.doc(userId).update(profileUpdates);
      }
      return null; // Success, no error message needed
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  // Get a user profile by username
  Future<Profile?> getProfileByUsername(String username) async {
    try {
      // First, try the direct query on Profile collection
      QuerySnapshot profileQuery = await profileCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      if (profileQuery.docs.isNotEmpty) {
        return Profile.fromMap(profileQuery.docs.first.data() as Map<String, dynamic>);
      }
      
      // If not found directly, try through UserMap collection
      QuerySnapshot userMapQuery = await userMapCollection
          .where(FieldPath.documentId, isEqualTo: username)
          .limit(1)
          .get();
      
      if (userMapQuery.docs.isEmpty) {
        return null;
      }
      
      String userId = userMapQuery.docs.first['userId'] as String;
      DocumentSnapshot profileDoc = await profileCollection.doc(userId).get();
      
      if (!profileDoc.exists) {
        return null;
      }
      
      return Profile.fromMap(profileDoc.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // Stream a user profile by userId
  Stream<Profile?> streamProfileByUserId(String userId) {
    return profileCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return Profile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Search for users by username prefix
  Future<List<Profile>> searchUsersByUsername(String searchQuery, {int limit = 20}) async {
    try {
      if (searchQuery.isEmpty) {
        return [];
      }
      
      // Convert search query to lowercase
      final lowercaseQuery = searchQuery.toLowerCase();
      
      // Query using the lowercase_username field
      final querySnapshot = await profileCollection
          .where('lowercase_username', isGreaterThanOrEqualTo: lowercaseQuery)
          .where('lowercase_username', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Profile.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
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
      return false;
    }
  }

  // Follow a user
  Future<bool> followUser(String targetUserId) async {
    try {
      if (currentUser == null) {
        return false;
      }

      final String currentUserId = currentUser!.uid;
      
      // Cannot follow yourself
      if (currentUserId == targetUserId) {
        return false;
      }
      
      // Use a transaction to ensure consistency
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get both user profiles
        final currentUserDoc = profileCollection.doc(currentUserId);
        final targetUserDoc = profileCollection.doc(targetUserId);
        
        final currentUserSnapshot = await transaction.get(currentUserDoc);
        final targetUserSnapshot = await transaction.get(targetUserDoc);
        
        if (!currentUserSnapshot.exists || !targetUserSnapshot.exists) {
          throw Exception('One or both profiles do not exist');
        }
        
        // Update following list of current user
        Map<String, dynamic> currentUserData = currentUserSnapshot.data() as Map<String, dynamic>;
        List<String> following = List<String>.from(currentUserData['following'] ?? []);
        
        if (!following.contains(targetUserId)) {
          following.add(targetUserId);
          transaction.update(currentUserDoc, {'following': following});
        }
        
        // Update followers list of target user
        Map<String, dynamic> targetUserData = targetUserSnapshot.data() as Map<String, dynamic>;
        List<String> followers = List<String>.from(targetUserData['followers'] ?? []);
        
        if (!followers.contains(currentUserId)) {
          followers.add(currentUserId);
          transaction.update(targetUserDoc, {'followers': followers});
        }
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Unfollow a user
  Future<bool> unfollowUser(String targetUserId) async {
    try {
      if (currentUser == null) {
        return false;
      }

      final String currentUserId = currentUser!.uid;
      
      // Cannot unfollow yourself
      if (currentUserId == targetUserId) {
        return false;
      }
      
      // Use a transaction to ensure consistency
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get both user profiles
        final currentUserDoc = profileCollection.doc(currentUserId);
        final targetUserDoc = profileCollection.doc(targetUserId);
        
        final currentUserSnapshot = await transaction.get(currentUserDoc);
        final targetUserSnapshot = await transaction.get(targetUserDoc);
        
        if (!currentUserSnapshot.exists || !targetUserSnapshot.exists) {
          throw Exception('One or both profiles do not exist');
        }
        
        // Remove from following list of current user
        Map<String, dynamic> currentUserData = currentUserSnapshot.data() as Map<String, dynamic>;
        List<String> following = List<String>.from(currentUserData['following'] ?? []);
        
        if (following.contains(targetUserId)) {
          following.remove(targetUserId);
          transaction.update(currentUserDoc, {'following': following});
        }
        
        // Remove from followers list of target user
        Map<String, dynamic> targetUserData = targetUserSnapshot.data() as Map<String, dynamic>;
        List<String> followers = List<String>.from(targetUserData['followers'] ?? []);
        
        if (followers.contains(currentUserId)) {
          followers.remove(currentUserId);
          transaction.update(targetUserDoc, {'followers': followers});
        }
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if current user is following a specific user
  Future<bool> isFollowingUser(String targetUserId) async {
    try {
      if (currentUser == null) {
        return false;
      }

      DocumentSnapshot doc = await profileCollection.doc(currentUser!.uid).get();
      if (!doc.exists) {
        return false;
      }
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<String> following = List<String>.from(data['following'] ?? []);
      
      return following.contains(targetUserId);
    } catch (e) {
      return false;
    }
  }

  // Get followers list as Profile objects
  Future<List<Profile>> getFollowers(String userId) async {
    try {
      DocumentSnapshot doc = await profileCollection.doc(userId).get();
      if (!doc.exists) {
        return [];
      }
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<String> followerIds = List<String>.from(data['followers'] ?? []);
      
      if (followerIds.isEmpty) {
        return [];
      }
      
      List<Profile> followers = [];
      
      for (int i = 0; i < followerIds.length; i += 10) {
        int end = (i + 10 < followerIds.length) ? i + 10 : followerIds.length;
        List<String> batch = followerIds.sublist(i, end);
        
        QuerySnapshot querySnapshot = await profileCollection
            .where('userId', whereIn: batch)
            .get();
        
        followers.addAll(querySnapshot.docs
            .map((doc) => Profile.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
      }
      
      return followers;
    } catch (e) {
      return [];
    }
  }

  // Get following list as Profile objects
  Future<List<Profile>> getFollowing(String userId) async {
    try {
      DocumentSnapshot doc = await profileCollection.doc(userId).get();
      if (!doc.exists) {
        return [];
      }
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<String> followingIds = List<String>.from(data['following'] ?? []);
      
      if (followingIds.isEmpty) {
        return [];
      }
      
      List<Profile> following = [];
      
      for (int i = 0; i < followingIds.length; i += 10) {
        int end = (i + 10 < followingIds.length) ? i + 10 : followingIds.length;
        List<String> batch = followingIds.sublist(i, end);
        
        QuerySnapshot querySnapshot = await profileCollection
            .where('userId', whereIn: batch)
            .get();
        
        following.addAll(querySnapshot.docs
            .map((doc) => Profile.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
      }
      
      return following;
    } catch (e) {
      return [];
    }
  }


void debugSharedPreferences() async {
  print("Debugging SharedPreferences:");
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.getKeys().forEach((key) {
    print('$key: ${prefs.get(key)}');
  });
}

}