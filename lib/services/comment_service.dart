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

      // Update comment parameters
      Comment updatedComment = Comment(
        commentId: generateRandomId(),
        postId: comment.postId,
        commenterId: userID,
        message: comment.message,
        timesShared: 0,
      );
      await comments.doc(updatedComment.commentId).set(updatedComment.toMap());
      print("Comment created successfully!");
    } catch (e) {
      print("Error creating comment: $e");
    }
  }

  // Read all comments for a specific post
  Stream<List<Comment>> streamCommentsByPost(String postId) {
    return comments.where('PostID', isEqualTo: postId).snapshots().map((querySnapshot) {
      return querySnapshot.docs.map((doc) => Comment.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }
  
  // Delete an existing comment
  Future<void> deleteComment(String commentId) async {
    try {
      await comments.doc(commentId).delete();
      print("Comment deleted successfully!");
    } catch (e) {
      print("Error deleting comment: $e");
    }
  }
}
