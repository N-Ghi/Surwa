
import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String postID;
  final String posterID;
  final String description;
  final Timestamp dateCreated;
  String? imageUrl;

  Post({
    required this.postID,
    required this.posterID,
    required this.description,
    required this.dateCreated,
    this.imageUrl,
  });

  // Convert Post object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'PostID': postID,
      'PosterID': posterID,
      'Description': description,
      'DateCreated': dateCreated,
      'ImageUrl': imageUrl,
    };
  }

  // Create a Post object from Firestore data
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      postID: map['PostID'] ?? '',
      posterID: map['PosterID'] ?? '',
      description: map['Description'] ?? '',
      dateCreated: map['DateCreated'] ?? '',
      imageUrl: map['ImageUrl'],
    );
  }
}
