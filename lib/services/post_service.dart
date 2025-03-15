import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/services/image_picker_service.dart';
import 'package:surwa/data/models/post.dart'; // Import the Post model

class PostService {
  final CollectionReference posts = FirebaseFirestore.instance.collection('Post');

  final ImagePickerService imagePickerService = ImagePickerService();
  // Create a new post
  Future<void> createPost(Post post, File? imageFile) async {
    try {
      if (imageFile != null) {
        final imagePickerService = ImagePickerService();

        // Upload the image and get the URL
        String? imageUrl = await imagePickerService.uploadPostImage(imageFile, '${post.posterID}/${post.postID}');
        print("Image URL after upload: $imageUrl");

        // Explicitly assign the image URL if it's not null
        if (imageUrl != null) {
          post.imageUrl = imageUrl; // Make sure to assign it
        }

        print("Post imageUrl after assignment: ${post.imageUrl}");
      }

      // Log post details before saving
      print("Saving post: ${post.toMap()}");

      // Save post details in Firestore
      await posts.doc(post.postID).set(post.toMap());
      print("Post created successfully!");
    } catch (e) {
      print("Error creating post: $e");
    }
  }

  // Read all posts
  Stream<List<Post>> streamAllPosts() {
    return posts.snapshots().map((querySnapshot) {
      return querySnapshot.docs.map((doc) => Post.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  // Update an existing post
  Future<void> updatePost(Post post, File? imageFile) async {
  try {
    // If a new image file is provided, upload it and update the imageUrl
    if (imageFile != null) {
      final imagePickerService = ImagePickerService();

      // Upload the image and get the URL
      String? imageUrl = await imagePickerService.uploadPostImage(imageFile, '${post.posterID}/${post.postID}');
      print("Image URL after upload: $imageUrl");

      // Explicitly assign the image URL if it's not null
      if (imageUrl != null) {
        post.imageUrl = imageUrl; // Assign the new image URL to the post object
      }

      print("Post imageUrl after assignment: ${post.imageUrl}");
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
