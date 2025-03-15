import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:surwa/screens/test%20screens/create_comment.dart';
import 'package:surwa/services/image_picker_service.dart';
import 'package:surwa/services/post_service.dart';
import 'package:surwa/data/models/post.dart';
import 'package:surwa/services/id_randomizer.dart';

class PostTestScreen extends StatefulWidget {
  const PostTestScreen({super.key});

  @override
  State<PostTestScreen> createState() => _PostTestScreenState();
}

class _PostTestScreenState extends State<PostTestScreen> {
  final PostService _postService = PostService();
  final ImagePickerService _imagePickerService = ImagePickerService();

  File? _imageFile;
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _pickImage() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: RefreshProgressIndicator(),
          );
        },
      );

      // Pick image in background
      File? pickedImage = await _imagePickerService.pickImage(ImageSource.gallery);

      // Close loading indicator
      Navigator.of(context).pop();

      if (pickedImage != null) {
        setState(() => _imageFile = pickedImage);
      }
    } catch (e) {
      // Close loading indicator if there's an error
      Navigator.of(context, rootNavigator: true).pop();
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _createPost() async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Post'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Tell us about your post',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text("Pick Image"),
                  ),
                  if (_imageFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.file(
                          _imageFile!, 
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_descriptionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please provide a description")),
                    );
                    return;
                    }

                    Post post = Post(
                      postID: generateRandomId(),
                      posterID: "Oracle", // Use dynamic user ID
                      description: _descriptionController.text.trim(),
                      dateCreated: DateTime.now().toIso8601String(),
                      imageUrl: '', // Will be updated in PostService
                      timesShared: 0,
                    );

                    await _postService.createPost(post, _imageFile);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Post created successfully!")),
                    );
                    _clearForm();
                    Navigator.pop(context);
                  },
                  child: const Text('Post'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _clearForm() {
    _descriptionController.clear();
    setState(() {
      _imageFile = null;
    });
  }

  Future<void> _deletePost(String postID) async {
    await _postService.deletePost(postID);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Post deleted successfully!")),
    );
  }

Future<void> _updatePost(Post currentPost) async {
  TextEditingController updatedDescriptionController = TextEditingController(text: currentPost.description);
  File? updatedImageFile = _imageFile;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Update Post'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: updatedDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Enter updated description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text("Pick Image"),
                ),
                if (updatedImageFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        updatedImageFile,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Prepare updated post data
                  Post updatedPost = Post(
                    postID: currentPost.postID,
                    posterID: currentPost.posterID,
                    description: updatedDescriptionController.text,
                    dateCreated: currentPost.dateCreated,
                    imageUrl: currentPost.imageUrl, // Keep existing image URL unless updated
                    timesShared: currentPost.timesShared,
                  );

                  // If a new image file is provided, upload it and update the image URL
                  if (updatedImageFile != null) {
                    final imagePickerService = ImagePickerService();
                    String? imageUrl = await imagePickerService.uploadPostImage(updatedImageFile, '${currentPost.posterID}/${currentPost.postID}');
                    print("Image URL after upload: $imageUrl");

                    if (imageUrl != null) {
                      updatedPost.imageUrl = imageUrl;
                    }

                    print("Updated post imageUrl: ${updatedPost.imageUrl}");
                  }

                  // Call the update method with the new post data
                  await _postService.updatePost(updatedPost, updatedImageFile);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Post updated successfully!")),
                  );
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      );
    },
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Post Test Screen')),
    floatingActionButton: FloatingActionButton(
      onPressed: _createPost,
      child: const Icon(Icons.add),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          StreamBuilder<List<Post>>(
            stream: _postService.streamAllPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No posts available'));
              }

              List<Post> posts = snapshot.data!;
              return Expanded(
                child: ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    Post post = posts[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                            Image.network(
                              post.imageUrl!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 200,
                                    width: double.infinity,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported, size: 50),
                                  ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.description,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Posted: ${post.dateCreated}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OverflowBar(
                            alignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deletePost(post.postID),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _updatePost(post),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CommentTestScreen(postId: post.postID),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.comment, color: Colors.green),
                              ),
                            ],
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

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
