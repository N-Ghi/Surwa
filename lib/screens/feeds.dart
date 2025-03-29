import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surwa/data/models/comment.dart';
import 'package:surwa/data/models/post.dart';
import 'package:surwa/data/models/profile.dart';
import 'package:surwa/screens/market.dart';
import 'package:surwa/screens/message.dart';
import 'package:surwa/screens/profile_search.dart';
import 'package:surwa/screens/test_screens/AddProduct.dart';
import 'package:surwa/screens/test_screens/ViewPaymentsPage.dart';
import 'package:surwa/screens/test_screens/create_post.dart';
import 'package:surwa/screens/login.dart';
import 'package:surwa/screens/profile.dart';
import 'package:surwa/data/notifiers/auth_notifier.dart';
import 'package:surwa/services/comment_service.dart';
import 'package:surwa/services/post_service.dart';
import 'package:surwa/services/profile_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  final ProfileService _profileService = ProfileService();
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController();
  
  late TabController _tabController;
  List<Post> _discoverPosts = [];
  List<Post> _followingPosts = [];
  bool _isLoading = true;
  final Map<String, String> _usernameCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadPosts() {
    // Load Discover Posts (all posts except current user's)
    _postService.streamAllPostsExceptCurrentUser().listen(
      (posts) {
        setState(() {
          _discoverPosts = posts ?? [];
          _isLoading = false;
        });
      },
      onError: (error) {
        _handlePostLoadError(error);
      },
    );

    // Load Following Posts
    print("Getting posts by followed users");

    _postService.streamPostsByFollowedUsers().listen(
      (posts) {
        setState(() {
          _followingPosts = posts ?? [];
          print("Following posts: $posts");
        });
      },
      onError: (error) {
        _handlePostLoadError(error);
      },
    );
  }

  void _handlePostLoadError(dynamic error) {
    print("Error loading posts: $error");
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error loading posts: $error")),
    );
  }

  Widget drawer() {
    return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.message),
              title: Text('Messages'),
              onTap: () {
                // Navigate to settings page
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return MessagesScreen();
                }));
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                // Navigate to settings page
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ProfileScreen();
                }));
              },
            ),
            ListTile(
              leading: Icon(Icons.add_a_photo),
              title: Text('Posts'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return PostSetup();
                }));
              },
            ),
             ListTile(
              leading: Icon(Icons.sell),
              title: Text('Products'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return MarketScreen();
                }));
              },
            ),
             ListTile(
              leading: Icon(Icons.add),
              title: Text('Add Products'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return AddProductScreen();
                }));
              },
            ),
            ListTile(
              leading: Icon(Icons.payment),
              title: Text('Payments'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ViewPaymentsPage();
                }));
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                // Logout user
                AuthNotifier authNotifier = Provider.of<AuthNotifier>(context, listen: false);
                authNotifier.signOut();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
                  return LoginScreen();
                }));
              },
            ),
          ],
        ),
      );
  }
  
  Future<void> _addComment(String postId) async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add comment")),
      );
      return;
    }

    Comment comment = Comment(
      commentId: "", // Will be updated in CommentService
      postId: postId, // Use the parameter passed to this method
      commenterId: "", // Will be updated in CommentService
      message: _commentController.text.trim(),
      timeStamp: Timestamp.fromDate(DateTime.now()), // Will be updated in CommentService
    );

    // Pass the comment to the comment service
    await _commentService.createComment(comment);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Comment created successfully!")),
    );
    Navigator.of(context).pop();
    _clearForm();
  }
  
  void _clearForm() {
    _commentController.clear();
  }
  
  // Fetch and cache usernames
  Future<String> _getUsernameFromId(String userId) async {
    if (_usernameCache.containsKey(userId)) {
      return _usernameCache[userId]!;
    }
    
    try {
      final username = await _profileService.getUsernameFromUserId(userId);
      _usernameCache[userId] = username!;
      return username;
    } catch (e) {
      print("Error fetching username: $e");
      return "Unknown user";
    }
  }

  // Comment Section
  Future<void> _commentSection(Post post) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Makes it full-screen
      backgroundColor: Colors.black, // TikTok-style dark mode
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75, // Takes 75% of screen height
          padding: EdgeInsets.only(top: 10),
          child: Column(
            children: [
              // Title Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Comments", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Comment List
              Expanded(
                child: StreamBuilder<List<Comment>>(
                  stream: _commentService.streamCommentsByPost(post.postID),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Error loading comments", style: TextStyle(color: Colors.white)));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data == null || snapshot.data!.isEmpty) {
                      return Center(child: Text("No comments yet.", style: TextStyle(color: Colors.white70)));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final comment = snapshot.data![index];

                        return FutureBuilder<String?>(
                          future: _profileService.getUsernameFromUserId(comment.commenterId),
                          builder: (context, usernameSnapshot) {
                            if (!usernameSnapshot.hasData) return SizedBox.shrink();
                            String username = usernameSnapshot.data ?? "Unknown";

                            return FutureBuilder<Profile?>(
                              future: _profileService.getProfileByUsername(username),
                              builder: (context, profileSnapshot) {
                                String? profilePicUrl = profileSnapshot.data?.profilePicture;

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey.shade800,
                                    backgroundImage: profilePicUrl != null
                                        ? NetworkImage(profilePicUrl)
                                        : null,
                                    child: profilePicUrl == null ? Icon(Icons.person, color: Colors.white) : null,
                                  ),
                                  title: RichText(
                                    text: TextSpan(
                                      style: TextStyle(color: Colors.white),
                                      children: [
                                        TextSpan(text: "$username ", style: TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: comment.message),
                                      ],
                                    ),
                                  ),
                                  subtitle: Text(
                                    timeAgo(comment.timeStamp),
                                    style: TextStyle(color: Colors.white60, fontSize: 12),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Comment Input Field
              Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), // Prevents keyboard overlap
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border(top: BorderSide(color: Colors.white24)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Add a comment...",
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send, color: Colors.blueAccent),
                        onPressed: () => _addComment(post.postID),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Time Ago
  String timeAgo(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    return timeago.format(date, locale: 'en');
  }


  Widget _buildPostList(List<Post> posts) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_photography_outlined, size: 100),
            Text("No posts available"),
            Text("Follow more creators or explore!"),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl != null)
            Image.network(
              post.imageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / 
                          loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(Icons.error, color: Colors.red),
                  ),
                );
              },
            ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(post.description),
                SizedBox(height: 10),
                FutureBuilder<String>(
                  future: _getUsernameFromId(post.posterID),
                  builder: (context, snapshot) {
                    return Text("Posted by: ${snapshot.data ?? 'Loading...'}");
                  },
                ),
              ],
            ),
          ),
          _buildCommentSection(post)
        ],
      ),
    );
  }

  Widget _buildCommentSection(Post post) {
    return StreamBuilder<List<Comment>>(
      stream: _commentService.streamCommentsByPost(post.postID),
      builder: (context, snapshot) {
        int commentCount = snapshot.data?.length ?? 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () {
                _commentSection(post);
              },
              icon: Icon(Icons.comment)
            ),
            Text("$commentCount"),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Discover'),
            Tab(text: 'Following'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return ProfileSearch();
              }));
            },
            icon: Icon(Icons.search),
          ),
        ],
      ),
      drawer: drawer(),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text("Loading posts..."),
              ],
            ),
          )
        : TabBarView(
            controller: _tabController,
            children: [
              _buildPostList(_discoverPosts),
              _buildPostList(_followingPosts),
            ],
          ),
    );
  }
}