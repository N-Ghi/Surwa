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
    String? imageUrl = post.imageUrl;

    // Upload image if selected
    if (imageFile != null) {
      final imagePickerService = ImagePickerService();
      // Assuming 'posts' is a good storage path name for the post images
      imageUrl = await imagePickerService.uploadImage(imageFile, 'posts');
      print("Image URL: $imageUrl");
      
      // Update the post's imageUrl directly
      post.imageUrl = imageUrl;
    }

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
  Future<void> updatePost(String postID, Map<String, dynamic> updatedData) async {
    try {
      await posts.doc(postID).update(updatedData);
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
