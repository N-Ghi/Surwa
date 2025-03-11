import 'dart:io';
import 'package:flutter/material.dart';
import 'package:surwa/screens/test%20screens/create_comment.dart';
import 'package:surwa/services/id_randomizer.dart';
import 'package:surwa/services/post_service.dart';
import 'package:surwa/data/models/post.dart'; // Import Post model

class PostTestScreen extends StatefulWidget {
  @override
  _PostTestScreenState createState() => _PostTestScreenState();
}

class _PostTestScreenState extends State<PostTestScreen> {
  File? imageFile;
  final PostService _postService = PostService();

  // Show dialog to create post
  void createPost() {
    TextEditingController descriptionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Enter description',
                  border: OutlineInputBorder(),
                ),
              ),
              Row(
                children: [
                  Text("Profile Picture"),
                  SizedBox(width: 10.0),
                  TextButton(
                    onPressed: () async {
                      // Handle image selection here
                      // imageFile = await pickImage(); // Implement image picker functionality
                      setState(() {
                        imageFile = imageFile;
                      });
                    },
                    child: Text("Pick Image"),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Post post = Post(
                  postID: generateRandomId(),
                  posterID: "oralexam",
                  description: descriptionController.text,
                  dateCreated: DateTime.now().toIso8601String(),
                  imageUrl: imageFile?.path ?? '',
                  timesShared: 0,
                );
                _postService.createPost(post, imageFile);
                Navigator.pop(context);
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  // Delete a post
  void _deletePost(String postID) async {
    await _postService.deletePost(postID);
  }

  // Update a post
  void _updatePost(String postID) async {
    TextEditingController updatedDescriptionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: updatedDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Enter updated description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Post updatedPost = Post(
                  postID: postID,
                  posterID: "sampleUser123", // Use dynamic user ID
                  description: updatedDescriptionController.text,
                  dateCreated: DateTime.now().toIso8601String(),
                  imageUrl: imageFile?.path ?? '', // Use imageUrl if needed
                  timesShared: 1, // Example value, update as needed
                );
                _postService.updatePost(postID, updatedPost.toMap());
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Post Test Screen')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          createPost();
        },
        child: Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            StreamBuilder<List<Post>>(
              stream: _postService.streamAllPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No posts available'));
                }

                List<Post> posts = snapshot.data!;
                return Expanded(
                  child: ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      Post post = posts[index];
                      return ListTile(
                        title: Text(post.description),
                        subtitle: Text(post.dateCreated),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _deletePost(post.postID);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                _updatePost(post.postID);
                              },
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => CommentTestScreen(postId: post.postID)));
                              },
                              icon: Icon(Icons.comment),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
