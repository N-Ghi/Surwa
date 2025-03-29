import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/post.dart';
import 'package:surwa/data/models/profile.dart';
import 'package:surwa/screens/profile.dart';
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(username: profile.username),
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