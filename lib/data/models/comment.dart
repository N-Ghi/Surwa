class Comment {
  final String commentId;
  final String postId;
  final String commenterId;
  final String message;
  final int timesShared;

  Comment({
    required this.commentId,
    required this.postId,
    required this.commenterId,
    required this.message,
    required this.timesShared,
  });

  // Convert Comment object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'CommentID': commentId,
      'PostID': postId,
      'CommenterID': commenterId,
      'Message': message,
      'TimesShared': timesShared,
    };
  }

  // Create a Comment object from Firestore data
  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      commentId: map['CommentID'] ?? '',
      postId: map['PostID'] ?? '',
      commenterId: map['CommenterID'] ?? '',
      message: map['Message'] ?? '',
      timesShared: map['TimesShared'] ?? 0,
    );
  }
}
