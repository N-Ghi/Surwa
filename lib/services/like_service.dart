import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/likes.dart'; // Import the Like model

class LikeService {
  final CollectionReference likes = FirebaseFirestore.instance.collection('Likes');

  // Create a new like
  Future<void> createLike(Like like) async {
    try {
      await likes.doc(like.likeId).set(like.toMap());
      print("Like created successfully!");
    } catch (e) {
      print("Error creating like: $e");
    }
  }

  // Read all likes for a specific post
  Stream<List<Like>> streamLikesByPost(String postId) {
    return likes.where('PostID', isEqualTo: postId).snapshots().map((querySnapshot) {
      return querySnapshot.docs.map((doc) => Like.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  // Delete an existing like
  Future<void> deleteLike(String likeId) async {
    try {
      await likes.doc(likeId).delete();
      print("Like deleted successfully!");
    } catch (e) {
      print("Error deleting like: $e");
    }
  }
}
