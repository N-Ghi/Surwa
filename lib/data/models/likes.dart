class Like {
  final String likeId;
  final String postId;
  final String likerId;

  Like({
    required this.likeId,
    required this.postId,
    required this.likerId,
  });

  // Convert Like object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'LikeID': likeId,
      'PostID': postId,
      'LikerID': likerId,
    };
  }

  // Create a Like object from Firestore data
  factory Like.fromMap(Map<String, dynamic> map) {
    return Like(
      likeId: map['LikeID'] ?? '',
      postId: map['PostID'] ?? '',
      likerId: map['LikerID'] ?? '',
    );
  }
}
