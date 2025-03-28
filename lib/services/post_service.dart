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
        dateCreated: Timestamp.fromDate(DateTime.now()),
        imageUrl: imageUrl,
      );
      
      // Create a batch to ensure both operations succeed or fail together
      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      // 1. Create/update the parent document
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('Post').doc(userID);
      batch.set(userDocRef, {
        'userID': userID,
        'lastUpdated': Timestamp.now()
      }, SetOptions(merge: true));
      
      // 2. Create the actual post in the subcollection
      DocumentReference postDocRef = userDocRef.collection('posts').doc(postID);
      batch.set(postDocRef, updatedPost.toMap());
      
      // Commit the batch
      await batch.commit();
      
      print("Post created successfully with ID: $postID");
      print("Post data: ${updatedPost.toMap()}");
      
    } catch (e) {
      print("Error creating post: $e");
    }
  }
  
  // Get all posts except those by the current user
  Stream<List<Post>> streamAllPostsExceptCurrentUser() {
    String? userID = currentUser?.uid;
    
    return FirebaseFirestore.instance.collection('Post').snapshots().asyncMap(
      (snapshot) async {
        List<Post> allPosts = [];
        
        print('Fetched ${snapshot.docs.length} users');
        
        for (var userDoc in snapshot.docs) {
          print('Checking user: ${userDoc.id}');
          
          if (userDoc.id == userID) {
            print('Skipping current user: $userID');
            continue;
          }
          
          // Use correct capitalization here - "DateCreated" not "dateCreated"
          var postDocs = await FirebaseFirestore.instance
              .collection('Post')
              .doc(userDoc.id)
              .collection('posts')
              .orderBy('DateCreated', descending: true)  // Capitalized field name
              .get();
          
          print('User ${userDoc.id} has ${postDocs.docs.length} posts');
          
          allPosts.addAll(postDocs.docs.map((doc) => Post.fromMap(doc.data())).toList());
        }
        
        print('Total posts retrieved: ${allPosts.length}');
        return allPosts;
      },
    );
  }
  
  // Get all posts by followed users
  Stream<List<Post>> streamPostsByFollowedUsers() {
    String? userID = currentUser?.uid;
    
    return FirebaseFirestore.instance.collection('Profile').doc(userID).snapshots().asyncMap(
      (userDoc) async {
        List<Post> allPosts = [];
        
        print('Fetched user: $userID');
        
        // Get the list of users that the current user is following
        List<String> following = List.from(userDoc.data()?['following'] ?? []);
        
        print('User $userID is following ${following.length} users');
        
        for (var followedUserID in following) {
          print('Checking user: $followedUserID');
          
          var postDocs = await FirebaseFirestore.instance
              .collection('Post')
              .doc(followedUserID)
              .collection('posts')
              .orderBy('DateCreated', descending: true)  // Capitalized field name
              .get();
          
          print('User $followedUserID has ${postDocs.docs.length} posts');
          
          allPosts.addAll(postDocs.docs.map((doc) => Post.fromMap(doc.data())).toList());
        }
        
        print('Total posts retrieved: ${allPosts.length}');
        return allPosts;
      },
    );
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
        .collection('posts') // Updated to 'posts'
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Post.fromMap(doc.data()))
              .toList();
        });
  }

  // Stream posts by a specific user
  Stream<List<Post>> streamPostsByUserId(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('Post')
        .doc(userId)
        .collection('posts')
        .orderBy('DateCreated', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Post.fromMap(doc.data()))
              .toList();
        });
  }
  
  // Stream a single post by its ID
  Stream<Post?> streamPostById(String postID) {
    String? userID = currentUser?.uid;
    if (userID == null) {
      return Stream.value(null);
    }

    return FirebaseFirestore.instance
        .collection('Post')
        .doc(userID)
        .collection('posts')
        .doc(postID)
        .snapshots()
        .map((doc) => doc.exists ? Post.fromMap(doc.data()!) : null);
  }
  
  // Delete an existing post and its associated comments
  Future<bool> deletePost(String postID) async {
    try{
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
      
      // Then delete the post itself using the correct path
      await FirebaseFirestore.instance
          .collection('Post')
          .doc(currentUser!.uid)
          .collection('posts') // Updated to 'posts'
          .doc(postID)
          .delete();

      print("Post and all associated comments deleted successfully!");
      return true;
    } catch (e) {
      print("Error deleting post and comments: $e");
      return false;
    }
  }

}
