import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/post.dart';
import 'package:surwa/data/models/profile.dart';
import 'package:surwa/services/profile_service.dart';
import 'package:intl/intl.dart';

class ProfileSearch extends StatefulWidget {
  const ProfileSearch({super.key});

  @override
  _ProfileSearchState createState() => _ProfileSearchState();
}

class _ProfileSearchState extends State<ProfileSearch> {
  final ProfileService _profileService = ProfileService();
  final TextEditingController _searchController = TextEditingController();
  List<Profile> _searchResults = [];
  bool _isSearching = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Function to perform the search query
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Use the service method to search users
      final profiles = await _profileService.searchUsersByUsername(query);

      setState(() {
        _searchResults = profiles;
        _isSearching = false;
      });
    } catch (e) {
      print("Error searching profiles: $e");
      setState(() {
        _isSearching = false;
      });
      
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching for users'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Users'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: TextStyle(color: Colors.black),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a username...',
                hintStyle: TextStyle(color: Colors.black45),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
              onChanged: (value) {
                // Debounce search to prevent excessive queries
                if (value.length >= 2) {
                  Future.delayed(Duration(milliseconds: 300), () {
                    if (value == _searchController.text) {
                      _performSearch(value);
                    }
                  });
                } else if (value.isEmpty) {
                  setState(() {
                    _searchResults = [];
                  });
                }
              },
            ),
          ),
          if (_isSearching)
            Center(child: CircularProgressIndicator())
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('No users found matching "${_searchController.text}"'),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final profile = _searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profile.profilePicture != null && profile.profilePicture!.isNotEmpty
                          ? NetworkImage(profile.profilePicture!)
                          : null,
                      child: profile.profilePicture == null || profile.profilePicture!.isEmpty
                          ? Icon(Icons.person)
                          : null,
                    ),
                    title: Text(profile.username),
                    subtitle: Text(profile.name),
                    onTap: () {
                      // Pass the entire profile object instead of just the username
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(profile: profile),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// Modified to accept a Profile object instead of just username
class UserProfileScreen extends StatefulWidget {
  final Profile profile;

  const UserProfileScreen({super.key, required this.profile});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ProfileService _profileService = ProfileService();
  late Profile _profile;
  bool _isLoading = false;
  String? _error;
  bool _isLoadingPosts = true;
  bool _isFollowing = false;
  List<Post> _userPosts = [];
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _checkIfCurrentUser();
    await _checkFollowStatus();
    await _loadUserPosts();
  }

  Future<void> _checkIfCurrentUser() async {
    final currentUserProfile = await _profileService.getLoggedInUserProfile();
    if (currentUserProfile != null) {
      setState(() {
        _isCurrentUser = currentUserProfile.userId == _profile.userId;
      });
    }
  }

  Future<void> _checkFollowStatus() async {
    if (_isCurrentUser) return;

    final currentUserProfile = await _profileService.getLoggedInUserProfile();
    if (currentUserProfile != null) {
      setState(() {
        _isFollowing = currentUserProfile.following.contains(_profile.userId);
      });
    }
  }

  Future<void> _loadUserPosts() async {
    setState(() {
      _isLoadingPosts = true;
    });

    try {
      // Query posts by the user's ID
      final querySnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('PosterID', isEqualTo: _profile.userId)
          .orderBy('DateCreated', descending: true)
          .get();

      final posts = querySnapshot.docs
          .map((doc) => Post.fromMap(doc.data()))
          .toList();

      setState(() {
        _userPosts = posts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      print("Error loading posts: $e");
      setState(() {
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_isCurrentUser) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserProfile = await _profileService.getLoggedInUserProfile();
      if (currentUserProfile == null) {
        throw Exception('Current user profile not found');
      }

      // Initialize lists if they're null
      List<String> currentUserFollowing = currentUserProfile.following ?? [];
      List<String> targetUserFollowers = _profile.followers ?? [];

      if (_isFollowing) {
        // Unfollow: Remove target user from current user's following list
        currentUserFollowing.remove(_profile.userId);
        
        // Remove current user from target user's followers list
        targetUserFollowers.remove(currentUserProfile.userId);
      } else {
        // Follow: Add target user to current user's following list
        if (!currentUserFollowing.contains(_profile.userId)) {
          currentUserFollowing.add(_profile.userId);
        }
        
        // Add current user to target user's followers list
        if (!targetUserFollowers.contains(currentUserProfile.userId)) {
          targetUserFollowers.add(currentUserProfile.userId);
        }
      }

      // Update current user's following list
      await FirebaseFirestore.instance
          .collection('Profile')
          .doc(currentUserProfile.userId)
          .update({'following': currentUserFollowing});

      // Update target user's followers list
      await FirebaseFirestore.instance
          .collection('Profile')
          .doc(_profile.userId)
          .update({'followers': targetUserFollowers});

      // Update local state
      setState(() {
        _isFollowing = !_isFollowing;
        _profile = Profile(
          userId: _profile.userId,
          username: _profile.username,
          name: _profile.name,
          profilePicture: _profile.profilePicture,
          role: _profile.role,
          followers: targetUserFollowers,
          following: _profile.following,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isFollowing ? 'Following' : 'Unfollowed')),
      );
    } catch (e) {
      print("Error toggling follow status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating follow status')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Method to refresh the profile data
  Future<void> _refreshProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final updatedProfile = await _profileService.getProfileByUsername(_profile.username);
      
      if (updatedProfile == null) {
        setState(() {
          _error = 'Failed to refresh profile';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _profile = updatedProfile;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile refreshed'))
      );
    } catch (e) {
      setState(() {
        _error = 'Error refreshing profile: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_profile.username),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildProfileView(),
    );
  }

  Widget _buildPostItem(Post post) {
    // Format timestamp
    String formattedDate = '';
    try {
      formattedDate = DateFormat('MMM d, yyyy • h:mm a')
          .format(post.dateCreated.toDate());
    } catch (e) {
      formattedDate = 'Date unknown';
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header with user info
          ListTile(
            leading: CircleAvatar(
              backgroundImage: _profile.profilePicture != null && _profile.profilePicture!.isNotEmpty
                  ? NetworkImage(_profile.profilePicture!)
                  : null,
              child: _profile.profilePicture == null || _profile.profilePicture!.isEmpty
                  ? Icon(Icons.person)
                  : null,
            ),
            title: Text(_profile.username),
            subtitle: Text(formattedDate),
          ),
          
          // Post description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(post.description),
          ),
          
          // Post image (if any)
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: 300,
              ),
              child: Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  );
                },
              ),
            ),
            
          // Post actions
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.favorite_border),
                  onPressed: () {
                    // Like functionality would go here
                  },
                ),
                IconButton(
                  icon: Icon(Icons.comment_outlined),
                  onPressed: () {
                    // Comment functionality would go here
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: _profile.profilePicture != null && _profile.profilePicture!.isNotEmpty
                    ? NetworkImage(_profile.profilePicture!)
                    : null,
                child: _profile.profilePicture == null || _profile.profilePicture!.isEmpty
                    ? Icon(Icons.person, size: 40)
                    : null,
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_profile.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('@${_profile.username}', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn((_profile.followers.length ?? 0).toString(), 'Followers'),
                        _buildStatColumn((_profile.following.length ?? 0).toString(), 'Following'),
                        _buildStatColumn(_userPosts.length.toString(), 'Posts'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Follow button (only shown if not the current user)
        if (!_isCurrentUser)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing ? Colors.grey[300] : Colors.blue,
                  foregroundColor: _isFollowing ? Colors.black : Colors.white,
                ),
                child: Text(_isFollowing ? 'Following' : 'Follow'),
              ),
            ),
          ),
        
        Divider(),
        
        // Posts section
        Expanded(
          child: _isLoadingPosts
              ? Center(child: CircularProgressIndicator())
              : _userPosts.isEmpty
                  ? Center(child: Text('No posts yet'))
                  : ListView.builder(
                      itemCount: _userPosts.length,
                      itemBuilder: (context, index) {
                        return _buildPostItem(_userPosts[index]);
                      },
                    ),
        ),
      ],
    );
  }

}