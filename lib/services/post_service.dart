import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:surwa/services/id_randomizer.dart';
import 'package:surwa/services/image_picker_service.dart';
import 'package:surwa/data/models/post.dart';
import 'package:surwa/services/profile_service.dart';

class PostService {

  final CollectionReference posts = FirebaseFirestore.instance.collection('Post');
  final CollectionReference comments = FirebaseFirestore.instance.collection('Comment');
  final ImagePickerService imagePickerService = ImagePickerService();
  final ProfileService profile = ProfileService();
  

  // Get current logged-in user
  auth.User? get currentUser => auth.FirebaseAuth.instance.currentUser;

  // Create a new post
  Future<void> createPost(Post post, File? imageFile) async {
    try {
      // Generate a new post ID
      final String postID = generateRandomId();
      String? userID = currentUser?.uid;
      if (userID == null) return;
      
      String? imageUrl;

      // Upload image if available
      if (imageFile != null) {
        final imagePickerService = ImagePickerService();
        imageUrl = await imagePickerService.uploadPostImage(imageFile, '$userID/$postID');
      }

      // Update Post parameters
      Post updatedPost = Post(
        postID: postID,
        posterID: userID, 
        description: post.description,
        dateCreated: DateTime.now().toString(),
        imageUrl: imageUrl,
        timesShared: 0,
      );

      // Save post details in Firestore with the correct structure
      await posts.doc(userID).collection(userID).doc(postID).set(updatedPost.toMap());

    } catch (e) {
      print("Error creating post: $e");
    }
  }
  // Read all posts except current user's
  Stream<List<Post>> streamAllPostsExceptCurrentUser() {
    String? userID = currentUser?.uid;
    
    return FirebaseFirestore.instance
        .collection('Post')
        .snapshots()
        .asyncMap((snapshot) async {
          List<Post> allPosts = [];
          
          // For each user document
          for (var userDoc in snapshot.docs) {
            // Skip current user
            if (userDoc.id == userID) continue;
            
            // Get all posts under this user document
            var postDocs = await FirebaseFirestore.instance
                .collection('Post')
                .doc(userDoc.id)
                .collection(userDoc.id)
                .get();
            
            // Convert to Post objects and add to list
            allPosts.addAll(postDocs.docs
                .map((doc) => Post.fromMap(doc.data() as Map<String, dynamic>))
                .toList());
          }
          
          return allPosts;
        });
  }

  // Read posts by current user
  Stream<List<Post>> streamPostsByUser() {
    String? userID = currentUser?.uid;
    if (userID == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('Post')
        .doc(userID)
        .collection(userID)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Post.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
        });
  }

  // Delete an existing post and its associated comments
  Future<void> deletePost(String postID) async {
  String? userID = currentUser?.uid;
  if (userID == null) return;
  
  try {
    // First, delete all comments associated with this post
    final commentsQuery = await comments
        .where('postID', isEqualTo: postID)
        .get();
    
    // Create a batch to delete all comments in a single operation
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in commentsQuery.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    
    // Then delete the post itself using the path that matches your structure
    await posts.doc(userID).collection(userID).doc(postID).delete();
    print("Post and all associated comments deleted successfully!");
  } catch (e) {
    print("Error deleting post and comments: $e");
  }
}

}
