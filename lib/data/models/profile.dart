class Profile {
  final String username;
  final String name;
  final String? profilePicture;
  final String role;
  final List<String> followers;
  final List<String> following;

  Profile({
    required this.username,
    required this.name,
    this.profilePicture,
    required this.role,
    this.followers = const [],
    this.following = const [],
  });

  // Convert a Profile object to a Map
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'name': name,
      'profilePicture': profilePicture ?? '',
      'role': role,
      'followers': followers,
      'following': following,
    };
  }

  // Create a Profile object from a Firestore document
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      username: map['username'] ?? '',
      name: map['name'] ?? '',
      profilePicture: map['profilePicture'],
      role: map['role'] ?? '',
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
    );
  }
}
