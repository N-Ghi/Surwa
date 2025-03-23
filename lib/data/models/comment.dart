import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String commentId;
  final String postId;
  final String commenterId;
  final String message;
  final Timestamp timeStamp;

  Comment({
    required this.commentId,
    required this.postId,
    required this.commenterId,
    required this.message,
    required this.timeStamp,
  });

  // Convert Comment object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'CommentID': commentId,
      'PostID': postId,
      'CommenterID': commenterId,
      'Message': message,
      'TimeStamp': timeStamp,
    };
  }

  // Create a Comment object from Firestore data
  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      commentId: map['CommentID'] ?? '',
      postId: map['PostID'] ?? '',
      commenterId: map['CommenterID'] ?? '',
      message: map['Message'] ?? '',
      timeStamp: map['TimeStamp'] ?? Timestamp.now(),
    );
  }
}
