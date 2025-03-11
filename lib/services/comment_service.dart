import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/comment.dart'; // Import the Comment model

class CommentService {
  final CollectionReference comments = FirebaseFirestore.instance.collection('Comment');

  // Create a new comment
  Future<void> createComment(Comment comment) async {
    try {
      await comments.doc(comment.commentId).set(comment.toMap());
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

  // Update an existing comment
  Future<void> updateComment(String commentId, Map<String, dynamic> updatedData) async {
    try {
      await comments.doc(commentId).update(updatedData);
      print("Comment updated successfully!");
    } catch (e) {
      print("Error updating comment: $e");
    }
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
