class Profile {
  final String userId; // Firebase-generated user ID
  final String username;
  final String name;
  final String lowercase_username;
  final String? profilePicture;
  final String role;
  final List<String> followers;
  final List<String> following;

  Profile({
    required this.userId,
    required this.username,
    required this.name,
    required this.lowercase_username,
    this.profilePicture,
    required this.role,
    this.followers = const [],
    this.following = const [],
  });

  // Implement copyWith to allow updates
  Profile copyWith({
    String? userId,
    String? username,
    String? name,
    String? lowercase_username,
    String? profilePicture,
    String? role,
    List<String>? followers,
    List<String>? following,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      name: name ?? this.name,
      lowercase_username: lowercase_username ?? this.lowercase_username,
      profilePicture: profilePicture ?? this.profilePicture,
      role: role ?? this.role,
      followers: followers ?? this.followers,
      following: following ?? this.following,
    );
  }

  // Convert a Profile object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'name': name,
      'lowercase_username': lowercase_username,
      'profilePicture': profilePicture ?? '',
      'role': role,
      'followers': followers,
      'following': following,
    };
  }

  // Create a Profile object from a Firestore document
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      name: map['name'] ?? '',
      lowercase_username: map['lowercase_username'] ?? '',
      profilePicture: map['profilePicture'],
      role: map['role'] ?? '',
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
    );
  }
}

  

