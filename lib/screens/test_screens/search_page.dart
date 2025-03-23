import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/profile.dart';
import 'package:surwa/services/profile_service.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
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
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a username...',
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

  const UserProfileScreen({Key? key, required this.profile}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ProfileService _profileService = ProfileService();
  late Profile _profile;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // We already have the profile, so no need to load it again
    _profile = widget.profile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.username),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(onPressed: () => _refreshProfile(), icon: Icon(Icons.refresh), tooltip: 'Refresh',),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                          _buildStatColumn(_profile.followers?.length.toString() ?? '0', 'Followers'),
                          _buildStatColumn(_profile.following?.length.toString() ?? '0', 'Following'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          // Additional profile information can be displayed here
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "This is ${_profile.username}'s profile",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}