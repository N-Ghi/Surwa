import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:surwa/data/models/message.dart';
import 'package:surwa/screens/chat_screen.dart';
import 'package:surwa/screens/test_screens/create_user.dart';
import 'package:surwa/screens/test_screens/login_page.dart';
import 'package:surwa/screens/test_screens/settings.dart';
import 'package:surwa/services/auth_service.dart';
import 'package:surwa/services/profile_service.dart';
import 'package:surwa/services/post_service.dart';
import 'package:surwa/data/models/profile.dart';
import 'package:surwa/data/models/post.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final String? username; // Optional username parameter to view other profiles
  const ProfileScreen({this.username, super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  File? _selectedImage;
  Profile? _profile;
  User? _currentUser;
  bool _isLoading = true;
  bool _isCurrentUserProfile = true;
  bool _isFollowing = false;
  List<Post> _userPosts = [];
  int _postCount = 0;
  List<Profile> _followers = [];
  List<Profile> _following = [];
  
  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.username != null) {
        // Loading someone else's profile
        _profile = await _profileService.getProfileByUsername(widget.username!);
        _isCurrentUserProfile = false;
        
        if (_profile != null && _currentUser != null) {
          // Check if current user is following this profile
          _isFollowing = await _profileService.isFollowingUser(_profile!.userId);
          
          // Load other user's posts
          _loadOtherUserPosts(_profile!.userId);
        }
      } else {
        // Loading current user's profile
        _profile = await _profileService.getLoggedInUserProfile();
        _isCurrentUserProfile = true;
        
        // Load current user's posts
        _loadCurrentUserPosts();
      }

      if (_profile != null) {
        _usernameController.text = _profile!.username;
        _nameController.text = _profile!.name;        
        
        // Load followers and following
        _followers = await _profileService.getFollowers(_profile!.userId);
        _following = await _profileService.getFollowing(_profile!.userId);
      }
    } catch (e) {
      print("Error loading profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile')),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _loadCurrentUserPosts() {
    _postService.streamPostsByUser().listen((posts) {
      if (mounted) {
        setState(() {
          _userPosts = posts;
          _postCount = posts.length;
        });
      }
    });
  }
  
  void _loadOtherUserPosts(String userId) {
    _postService.streamPostsByUserId(userId).listen((posts) {
      if (mounted) {
        setState(() {
          _userPosts = posts;
          _postCount = posts.length;
        });
      }
    });
  }

  Future<void> _toggleFollow() async {
      if (_profile == null || _currentUser == null) return;

      // Check if the current user is trying to follow themselves
      if (_profile!.userId == _currentUser!.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You can't follow yourself")),
        );
        return;
      }
      
      bool success;
      if (_isFollowing) {
        success = await _profileService.unfollowUser(_profile!.userId);
        if (success) {
          setState(() {
            _isFollowing = false;
            _followers.removeWhere((follower) => follower.userId == _currentUser!.uid);
          });
        }
      } else {
        success = await _profileService.followUser(_profile!.userId);
        if (success) {
          setState(() {
            _isFollowing = true;
            // Add current user to followers list
            _profileService.getLoggedInUserProfile().then((currentUserProfile) {
              if (currentUserProfile != null && mounted) {
                setState(() {
                  _followers.add(currentUserProfile);
                });
              }
            });
          });
        }
      }
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${_isFollowing ? 'unfollow' : 'follow'} user')),
        );
      }
  }

  Future<void> _updateProfileForm() async {
    if (!mounted || !_isCurrentUserProfile) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: 'Username'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Change Profile Photo'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!mounted) return;

                Navigator.pop(dialogContext);
                setState(() {
                  _isLoading = true;
                });

                String? result = await _profileService.updateProfile(
                  name: _nameController.text.isNotEmpty ? _nameController.text : null,
                  username: _usernameController.text.isNotEmpty ? _usernameController.text : null,
                  newProfileImage: _selectedImage,
                );

                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result ?? 'Profile updated successfully!')),
                  );
                  
                  // Reload profile to show updated info
                  _loadProfile();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProfile() async {
    if (!_isCurrentUserProfile) return;
    
    // Confirmation dialog before deletion
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                setState(() {
                  _isLoading = true;
                });
                
                String? result = await _authService.deleteAccount();
                
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  
                  if (result == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Account deleted successfully')),
                    );
                    // Navigate to login or home screen
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result)),
                    );
                  }
                }
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showFollowersList() {
    _showUserListBottomSheet('Followers', _followers);
  }

  void _showFollowingList() {
    _showUserListBottomSheet('Following', _following);
  }

  void _showUserListBottomSheet(String title, List<Profile> users) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(),
              Expanded(
                child: users.isEmpty
                    ? Center(child: Text('No $title yet'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                                  ? NetworkImage(user.profilePicture!)
                                  : null,
                              child: user.profilePicture == null || user.profilePicture!.isEmpty
                                  ? Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(user.username),
                            subtitle: Text(user.name),
                            onTap: () {
                              Navigator.pop(context);
                              if (user.userId != _currentUser?.uid) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileScreen(username: user.username),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }
  }
  
  void _navigateToPostDetail(Post post) {
    // Implementation for navigating to post detail view
    // You can create a PostDetailScreen and navigate to it
    print("Navigate to post detail for post: ${post.postID}");
  }

  Future<void> _updateImage() async {
    if (!mounted) return;

    try {
      String? result = await _profileService.updateProfile(
        newProfileImage: _selectedImage,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? 'Profile Image updated successfully!')),
      );

      // Reload profile to show updated info
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isCurrentUserProfile ? 'Profile' : widget.username ?? ''),
          centerTitle: true,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile'), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 50),
              SizedBox(height: 10),
              Text('No profile found!'),
              if (_isCurrentUserProfile)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfileTestScreen()));
                  },
                  child: Icon(Icons.add),
                ),
            ],
          ),
        ),
      );
    }

    // Instagram-style profile screen
    return Scaffold(
      appBar: AppBar(
        title: Text(_profile!.username, style: TextStyle(fontWeight: FontWeight.bold)),
        leading: widget.username != null ? BackButton() : null,
        actions: [
          if (_isCurrentUserProfile)
            IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.settings),
                        title: Text('Settings'),
                        onTap: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SettingsPage()));
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete Account', style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          _deleteProfile();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProfile();
          if (_isCurrentUserProfile) {
            _loadCurrentUserPosts();
          } else if (_profile != null) {
            _loadOtherUserPosts(_profile!.userId);
          }
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Profile Image
                    GestureDetector(
                      onTap: () async{
                        if (_isCurrentUserProfile) {
                          await _pickImage();
                          if (_selectedImage != null) {
                            await _updateImage();
                          }
                        }
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : _profile!.profilePicture != null && _profile!.profilePicture!.isNotEmpty
                                    ? NetworkImage(_profile!.profilePicture!)
                                    : null,
                            child: (_selectedImage == null && 
                                    (_profile!.profilePicture == null || _profile!.profilePicture!.isEmpty))
                                ? Icon(Icons.person, size: 40)
                                : null,
                          ),
                          if (_isCurrentUserProfile)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.add_a_photo, size: 16, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 24),
                    // Stats (Posts, Followers, Following)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn(_userPosts.length, 'Posts'),
                          GestureDetector(
                            onTap: _showFollowersList,
                            child: _buildStatColumn(_followers.length, 'Followers'),
                          ),
                          GestureDetector(
                            onTap: _showFollowingList,
                            child: _buildStatColumn(_following.length, 'Following'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Name and Bio
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile!.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
              // Edit Profile or Follow Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _isCurrentUserProfile
                    ? OutlinedButton(
                        onPressed: _updateProfileForm,
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(double.infinity, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text('Edit Profile'),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(0, 36),
                                backgroundColor: _isFollowing ? Colors.grey.shade200 : Theme.of(context).primaryColor,
                                foregroundColor: _isFollowing ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: Text(_isFollowing ? 'Following' : 'Follow'),
                            ),
                          ),
                          SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              // Create a Message object to pass to the ChatScreen
                              final message = Message(
                                messageID: '',
                                senderID: FirebaseAuth.instance.currentUser!.uid, // Current user ID
                                receiverID: _profile!.userId, // ID of the profile user you're messaging
                                content: '', // Empty initially
                                status: MessageStatus.sent, // Initial status
                                dateCreated: Timestamp.fromDate(DateTime.now()), // Initial timestamp
                              );

                              // Navigate to the ChatScreen
                              Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(user: message)
                                )
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(0, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: Text('Message'),
                          ),
                        ],
                      ),
              ),
              SizedBox(height: 16),
              // Post Grid Header
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: IconButton(
                        icon: Icon(Icons.grid_on),
                        onPressed: () {},
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Expanded(
                      child: IconButton(
                        icon: Icon(Icons.person_pin_outlined),
                        onPressed: () {},
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Post Grid with real data
              _userPosts.isNotEmpty 
                  ? GridView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 1,
                        mainAxisSpacing: 1,
                      ),
                      itemCount: _userPosts.length,
                      itemBuilder: (context, index) {
                        final post = _userPosts[index];
                        return GestureDetector(
                          onTap: () => _navigateToPostDetail(post),
                          child: post.imageUrl != null && post.imageUrl!.isNotEmpty
                              ? Image.network(
                                  post.imageUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / 
                                              (loadingProgress.expectedTotalBytes ?? 1)
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade300,
                                      child: Center(
                                        child: Icon(Icons.error, color: Colors.red),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey.shade300,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text(
                                        post.description ?? '',
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                        );
                      },
                    )
                  : SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No Posts Yet', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(int count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}