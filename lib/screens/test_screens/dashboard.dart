import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surwa/data/models/post.dart';
import 'package:surwa/screens/test_screens/create_post.dart';
import 'package:surwa/screens/test_screens/profile.dart';
import 'package:surwa/data/notifiers/auth_notifier.dart';
import 'package:surwa/screens/test_screens/welcome_page.dart';
import 'package:surwa/services/post_service.dart';

class HomeScreen extends StatefulWidget {

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PostService _postService = PostService();
  List<Post> _allPosts = [];
  bool _isLoading = true;

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
                  ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(post.description),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {}, 
                      icon: Icon(Icons.comment)
                    ),
                    SizedBox(width: 5),
                    Text("${post.timesShared} "),
                    IconButton(
                      onPressed: () {}, 
                      icon: Icon(Icons.share),
                      tooltip: "Share Post",
                    ),
                    
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
