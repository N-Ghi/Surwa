import 'dart:io';
import 'package:surwa/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:surwa/data/models/post.dart';

class PostSetup extends StatefulWidget {
  const PostSetup({super.key});

  @override
  _PostSetupState createState() => _PostSetupState();
}

class _PostSetupState extends State<PostSetup> {
  final PostService _postService = PostService();
  TextEditingController _postController = TextEditingController();
  File? _selectedImage;
  List<Post> _userPosts = [];
  bool _isLoading = true;
  
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
      dateCreated: DateTime.now().toString(),
      imageUrl: null, // Will be updated in PostService
      timesShared: 0,
    );

    // Pass the selected image to the post service
    await _postService.createPost(post, _selectedImage);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Post created successfully!")),
    );
    Navigator.of(context).pop();
    _clearForm();
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
        return AlertDialog(
          title: Text("Create a new post"),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _postController,
                decoration: InputDecoration(hintText: "Add description"),
              ),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text("Select Image"),
              ),
              SizedBox(height: 10),
              if (_selectedImage != null) // Show indicator when image is selected
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
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
              onPressed: _addPost,
              child: Text("Post"),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> commentForm() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Comment on post"),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _postController,
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
                Navigator.of(context).pop();
              },
              child: Text("Comment"),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Post to your feed"),
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
          title: Text("Post to your feed"),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("No posts found"),
              ElevatedButton(
                onPressed: postForm,
                child: Text("Create Post"),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Post to your feed"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: postForm,
        child: Icon(Icons.add),
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
                  ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(post.description),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: commentForm, 
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
