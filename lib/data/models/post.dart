class Post {
  final String postID;
  final String posterID;
  final String description;
  final String dateCreated;
  late final String? imageUrl;
  final int timesShared;

  Post({
    required this.postID,
    required this.posterID,
    required this.description,
    required this.dateCreated,
    required this.imageUrl,
    required this.timesShared,
  });

  // Convert Post object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'PostID': postID,
      'PosterID': posterID,
      'Description': description,
      'DateCreated': dateCreated,
      'ImageUrl': imageUrl,
      'TimesShared': timesShared,
    };
  }

  // Create a Post object from Firestore data
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      postID: map['PostID'] ?? '',
      posterID: map['PosterID'] ?? '',
      description: map['Description'] ?? '',
      dateCreated: map['DateCreated'] ?? '',
      imageUrl: map['ImageUrl'] ?? '',
      timesShared: map['TimesShared'] ?? 0,
    );
  }
}
