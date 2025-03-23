import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/comment.dart'; // Import the Comment model
import 'package:surwa/services/comment_service.dart';

class CommentTestScreen extends StatefulWidget {
  final String postId;
  const CommentTestScreen({super.key, required this.postId});
  @override
  _CommentTestScreenState createState() => _CommentTestScreenState();
}

class _CommentTestScreenState extends State<CommentTestScreen> {
  final CommentService _commentService = CommentService();
  final TextEditingController _postIdController = TextEditingController();
  final TextEditingController _commenterIdController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String? selectedCommentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Comment Test Screen")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            children: [
            TextField(
              controller: _commenterIdController,
              decoration: InputDecoration(labelText: "Commenter ID"),
            ),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(labelText: "Message"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
              String commentId = FirebaseFirestore.instance.collection('Comment').doc().id;
              // Create a Comment object
              final newComment = Comment(
                commentId: commentId,
                postId: widget.postId,
                commenterId: _commenterIdController.text,
                message: _messageController.text,
                timeStamp: Timestamp.fromDate(DateTime.now()),
              );
              // Use the createComment method with the Comment object
              _commentService.createComment(newComment);
              print("Comment created: $newComment");
              },
              child: Text("Create Comment"),
            ),
            SizedBox(height: 20),
            Text("Comments"),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<Comment>>(
              stream: _commentService.streamCommentsByPost(_postIdController.text),
              builder: (context, snapshot) {
              if (!snapshot.hasData) {
                print("Loading comments...");
                return CircularProgressIndicator();
              }
              final comments = snapshot.data!;
              print("Comments loaded: $comments");
              return ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                final comment = comments[index];
                return ListTile(
                  title: Text(comment.message),
                  trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                      selectedCommentId = comment.commentId;
                      _messageController.text = comment.message;
                      });
                      print("Editing comment: $comment");
                    },
                    ),
                    IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _commentService.deleteComment(comment.commentId);
                      print("Deleting comment: $comment");
                    },
                    ),
                  ],
                  ),
                );
                },
              );
              },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
