import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surwa/data/models/comment.dart';
import 'package:surwa/data/models/post.dart';
import 'package:surwa/screens/test_screens/create_post.dart';
import 'package:surwa/screens/test_screens/profile.dart';
import 'package:surwa/data/notifiers/auth_notifier.dart';
import 'package:surwa/screens/test_screens/settings.dart';
import 'package:surwa/screens/test_screens/welcome_page.dart';
import 'package:surwa/services/comment_service.dart';
import 'package:surwa/services/post_service.dart';
import 'package:surwa/services/profile_service.dart';

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
  
  void _loadAllPosts() {
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
          ],
        ),
      );
  }
  
  Future<void> commentForm(Post post) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Comment on post"),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Make the dialog smaller
            children: [
              TextField(
                controller: _commentController,
                decoration: InputDecoration(hintText: "Add comment"),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _addComment(post.postID);
                Navigator.of(context).pop();
              },
              child: Text("Comment"),
            ),
          ],
        );
      },
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
      timesShared: 0,
    );

    // Pass the comment to the comment service
    await _commentService.createComment(comment);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Comment created successfully!")),
    );
    _clearForm();
  }
  
  void _clearForm() {
    _commentController.clear();
  }
  
  // Add this method to fetch and cache usernames
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

  


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Home"),
          centerTitle: true,
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
                return Settings();
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
                            commentForm(post);
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
