import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:surwa/services/id_randomizer.dart';
import 'package:surwa/services/image_picker_service.dart';
import 'package:surwa/data/models/post.dart';
import 'package:surwa/services/profile_service.dart';

class PostService {

  final CollectionReference posts = FirebaseFirestore.instance.collection('Post');
  final ImagePickerService imagePickerService = ImagePickerService();
  final ProfileService profile = ProfileService();
  

  // Get current logged-in user
  auth.User? get currentUser => auth.FirebaseAuth.instance.currentUser;

  // Create a new post
  Future<void> createPost(Post post, File? imageFile) async {
    try {
      String? imageUrl;

      // Upload image if available
      if (imageFile != null) {
        final imagePickerService = ImagePickerService();
        imageUrl = await imagePickerService.uploadPostImage(imageFile, currentUser!.uid);
      }

      // Update Post parameters
      Post updatedPost = Post(
        postID: generateRandomId(),
        posterID: currentUser!.uid,
        description: post.description,
        dateCreated: DateTime.now().toString(),
        imageUrl: imageUrl,
        timesShared: 0,
      );

      // Save post details in Firestore
      await posts.doc(updatedPost.postID).set(updatedPost.toMap());

    } catch (e) {
      print("Error creating post: $e");
    }
  }

  // Read all posts
  Stream<List<Post>> streamAllPostsExceptCurrentUser() {
    String? userID = currentUser?.uid;
    
    return FirebaseFirestore.instance
        .collection('Post')
        .where('PosterID', isNotEqualTo: userID)
        .snapshots()
        .map((querySnapshot) {
          return querySnapshot.docs
              .map((doc) => Post.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
        });
  }

  // Read posts by a specific user
  Stream<List<Post>> streamPostsByUser() {
    String? userID = currentUser?.uid;
    if (userID == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('Post')
        .where('PosterID', isEqualTo: userID)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Post.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
        });
  }

  // Update an existing post
  Future<void> updatePost(Post post, File? imageFile) async {
  try {
    print("Starting updatePost for postID: ${post.postID}");

    // Debugging imageFile before checking it
    if (imageFile == null) {
      print("DEBUG: No image file provided to updatePost, skipping upload.");
    } else {
      print("DEBUG: Image file detected in updatePost: ${imageFile.path}");
    }

    // If a new image file is provided, upload it and update the imageUrl
    if (imageFile != null) {
      print("Image file provided: ${imageFile.path}");
      final imagePickerService = ImagePickerService();
      print("ImagePickerService instantiated");

      // Upload the image and get the URL
      String? imageUrl = await imagePickerService.uploadPostImage(imageFile, '${post.posterID}/${post.postID}');
      print("Image URL after upload: $imageUrl");

      // Explicitly assign the image URL if it's not null
      if (imageUrl != null) {
        post.imageUrl = imageUrl; // Assign the new image URL to the post object
        print("Post imageUrl after assignment: ${post.imageUrl}");
      } else {
        print("DEBUG: Image upload failed, imageUrl is null.");
      }
    }

    // Log post details before saving
    print("Updating post with data: ${post.toMap()}");

    // Update the post with the new data in Firestore
    await posts.doc(post.postID).update(post.toMap());
    print("Post updated successfully!");
  } catch (e) {
    print("Error updating post: $e");
  }
}

  // Delete an existing post
  Future<void> deletePost(String postID) async {
    try {
      await posts.doc(postID).delete();
      print("Post deleted successfully!");
    } catch (e) {
      print("Error deleting post: $e");
    }
  }
}
