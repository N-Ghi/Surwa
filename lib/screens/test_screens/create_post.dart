import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/comment.dart';
import 'package:surwa/data/models/profile.dart';
import 'package:surwa/services/comment_service.dart';
import 'package:surwa/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:surwa/data/models/post.dart';
import 'package:surwa/services/profile_service.dart';
import 'package:timeago/timeago.dart' as timeago;


class PostSetup extends StatefulWidget {
  const PostSetup({super.key});

  @override
  _PostSetupState createState() => _PostSetupState();
}

class _PostSetupState extends State<PostSetup> {
  final PostService _postService = PostService();
  final ProfileService _profileServices = ProfileService();
  final CommentService _commentService = CommentService();
  TextEditingController _postController = TextEditingController();
  TextEditingController _commentController = TextEditingController();
  File? _selectedImage;
  List<Post> _userPosts = [];
  bool _isLoading = true;
  Map<String, String> _usernameCache = {};
  
  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }
  
  void _loadUserPosts() {
    try {
      print("Starting to load user posts");
      _postService.streamPostsByUser().listen(
        (posts) {
          print("Received posts: ${posts?.length ?? 0}");
          setState(() {
            _userPosts = posts ?? [];
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
      print("Exception in _loadUserPosts: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _addPost() async {
    if (_postController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add description")),
      );
      return;
    }

    Post post = Post(
      postID: "", // Will be updated in PostService
      posterID: "", // Will be updated in PostService
      description: _postController.text.trim(),
      dateCreated: Timestamp.fromDate(DateTime.now()),
      imageUrl: null, // Will be updated in PostService
    );

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Creating post...")),
      );
      
      // Pass the selected image to the post service
      await _postService.createPost(post, _selectedImage);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post created successfully!")),
      );
      Navigator.of(context).pop();
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating post: $e")),
      );
    }
  }

  void _clearForm() {
    _postController.clear();
    setState(() {
      _selectedImage = null;
    });
  }
  
  Future<void> postForm() async {
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Create a new post"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _postController,
                      decoration: InputDecoration(hintText: "Add description"),
                      maxLines: 5,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await _pickImage();
                        setState(() {}); // Update StatefulBuilder state
                      },
                      child: Text("Select Image"),
                    ),
                    SizedBox(height: 10),
                    if (_selectedImage != null) // Show preview when image is selected
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: _addPost,
                  child: Text("Post"),
                ),
              ],
            );
          }
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
      postId: postId,
      commenterId: "", // Will be updated in CommentService
      message: _commentController.text.trim(),
      timeStamp: Timestamp.fromDate(DateTime.now())
    );

    try {
      // Pass the comment to the comment service
      await _commentService.createComment(comment);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Comment added successfully!")),
      );
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding comment: $e")),
      );
    }
  }

  Future<String> _getUsernameFromId(String userId) async {
    if (_usernameCache.containsKey(userId)) {
      return _usernameCache[userId]!;
    }
    
    try {
      final username = await _profileServices.getUsernameFromUserId(userId);
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
                          future: _profileServices.getUsernameFromUserId(comment.commenterId),
                          builder: (context, usernameSnapshot) {
                            if (!usernameSnapshot.hasData) return SizedBox.shrink();
                            String username = usernameSnapshot.data ?? "Unknown";

                            return FutureBuilder<Profile?>(
                              future: _profileServices.getProfileByUsername(username),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("My Posts"),
          centerTitle: true,
        ),
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
    if (_userPosts.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("My Posts"),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.post_add, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text("No posts found", style: TextStyle(fontSize: 18)),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: postForm,
                icon: Icon(Icons.add),
                label: Text("Create Post"),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text("My Posts"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: postForm,
            icon: Icon(Icons.post_add),
            tooltip: "Add Post",
          ),
        ],
      ),
      // View posts by user
      body: ListView.builder(
        itemCount: _userPosts.length,
        itemBuilder: (context, index) {
          final post = _userPosts[index];
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
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.description,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      FutureBuilder<String>(
                        future: _getUsernameFromId(post.posterID),
                        builder: (context, snapshot) {
                          return Text("Posted by: ${snapshot.data ?? 'Loading...'}");
                        },
                      ),
                      SizedBox(height: 4),
                      Text(
                          timeAgo(post.dateCreated),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StreamBuilder<List<Comment>>(
                        stream: _commentService.streamCommentsByPost(post.postID),
                        builder: (context, snapshot) {
                          int commentCount = snapshot.data?.length ?? 0;
                          return Row(
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
                      ),
                      
                      IconButton(
                        onPressed: () {
                          _showDeleteConfirmation(post);
                        },
                        icon: Icon(Icons.delete_outline),
                        tooltip: "Delete Post",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateStr;
    }
  }
  
  Future<void> _showDeleteConfirmation(Post post) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Post"),
          content: Text("Are you sure you want to delete this post?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                try {
                  await _postService.deletePost(post.postID);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Post deleted successfully")),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error deleting post: $e")),
                  );
                }
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  String timeAgo(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    return timeago.format(date, locale: 'en');
  }
}