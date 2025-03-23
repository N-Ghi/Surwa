import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surwa/data/models/comment.dart';
import 'package:surwa/data/models/post.dart';
import 'package:surwa/data/models/profile.dart';
import 'package:surwa/screens/test_screens/create_post.dart';
import 'package:surwa/screens/test_screens/profile.dart';
import 'package:surwa/data/notifiers/auth_notifier.dart';
import 'package:surwa/screens/test_screens/search_page.dart';
import 'package:surwa/screens/test_screens/settings.dart';
import 'package:surwa/screens/test_screens/welcome_page.dart';
import 'package:surwa/services/comment_service.dart';
import 'package:surwa/services/post_service.dart';
import 'package:surwa/services/profile_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomeScreen extends StatefulWidget {

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PostService _postService = PostService();
  final ProfileService _profileService = ProfileService();
  final CommentService _commentService = CommentService();
  TextEditingController _commentController = TextEditingController();
  List<Post> _allPosts = [];
  bool _isLoading = true;
  Map<String, String> _usernameCache = {};

  void initState() {
    super.initState();
    _loadAllPosts();
  }
  
  void _loadAllPosts() async{
    try {
      print("Starting to load user posts");
      _postService.streamAllPostsExceptCurrentUser().listen(
        (posts) {
          print("Received posts: ${posts?.length ?? 0}");
          setState(() {
            _allPosts = posts ?? [];
            _isLoading = false;
          });
        },
        onError: (error) {
          print("Error loading posts: $error");
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error loading posts: $error")),
          );
        },
      );
    } catch (e) {
      print("Exception in _loadAllPosts: $e");
      setState(() {
        _isLoading = false;
      });
    }
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
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                // Logout user
                AuthNotifier authNotifier = Provider.of<AuthNotifier>(context, listen: false);
                authNotifier.signOut();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
                  return WelcomePage();
                }));
              },
            ),
            ListTile(
              leading: Icon(Icons.search),
              title: Text('Search'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return SearchPage();
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


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Home"),
          centerTitle: true,
          actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return SettingsPage();
              }));
            },
            icon: Icon(Icons.settings),
          ),
        ],
        ),
        drawer: drawer(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Loading posts..."),
            ],
          ),
        ),
      );
    }
    
    // Check if posts exist
    if (_allPosts.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Home"),
          centerTitle: true,
          actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return SettingsPage();
              }));
            },
            icon: Icon(Icons.settings),
          ),
        ],
        ),
        drawer: drawer(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.no_photography_outlined, size: 100),
              Text("No creator has made a post yet."),
              Text("Be the first to create a post!"),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return SettingsPage();
              }));
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      drawer: drawer(),
      // View posts by creators
      body: ListView.builder(
        itemCount: _allPosts.length,
        itemBuilder: (context, index) {
          final post = _allPosts[index];
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
                StreamBuilder<List<Comment>>(
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
                )
              ],
            ),
          );
        },
      ),
    );
  }

}
