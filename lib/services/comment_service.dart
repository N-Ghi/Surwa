import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:surwa/data/models/comment.dart';
import 'package:surwa/services/id_randomizer.dart'; // Import the Comment model

class CommentService {
  final CollectionReference comments = FirebaseFirestore.instance.collection('Comment');

  // Create a new comment
  Future<void> createComment(Comment comment) async {
    try {
      String userID = FirebaseAuth.instance.currentUser!.uid;
      String commentID = generateRandomId();

      // Update comment parameters
      Comment updatedComment = Comment(
        commentId: commentID,
        postId: comment.postId,
        commenterId: userID,
        message: comment.message,
        timeStamp: Timestamp.fromDate(DateTime.now()),
      );

      // Store comment under: Comment/{userID}/comments/{commentID}
      await comments
          .doc(userID) // User document
          .collection('comments') // Subcollection for comments
          .doc(commentID) // Individual comment document
          .set(updatedComment.toMap());

      print("Comment created successfully!");
    } catch (e) {
      print("Error creating comment: $e");
    }
  }

  // Read all comments for a specific post
  Stream<List<Comment>> streamCommentsByPost(String postId) {
    return FirebaseFirestore.instance
        .collectionGroup('comments') // Searches all "comments" subcollections
        .where('PostID', isEqualTo: postId) // Filter by postId
        .orderBy('TimeStamp', descending: true) // Optional: Order by newest first
        .snapshots()
        .map((querySnapshot) {
          return querySnapshot.docs
              .map((doc) => Comment.fromMap(doc.data()))
              .toList();
        });
  }

  // Delete an existing comment
  Future<void> deleteComment(String commentId) async {
    try {
      // await comments.doc(commentId).delete();
      await comments
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('comments')
          .doc(commentId)
          .delete();
      print("Comment deleted successfully!");
    } catch (e) {
      print("Error deleting comment: $e");
    }
  }
}
