import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:surwa/data/models/message.dart';
import 'package:surwa/services/message_service.dart';
import 'package:surwa/services/profile_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final Message user;

  const ChatScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ProfileService _profileService = ProfileService();
  final MessageService _messageService = MessageService();
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  // Send message using MessageService
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = Message(
      collectionId: '',
      fromUserId: _currentUserId,
      toUserId: widget.user.toUserId,
      message: _messageController.text,
      status: 'sent', 
      timeStamp: DateTime.now().toIso8601String(),
    );

    // Add the message using MessageService
    await _messageService.addMessage(message);

    _messageController.clear();
  }

  // Get username from userId
  Future<String> _getUsername(String userId) async {
    if (userId == _currentUserId) return 'You';

    String? username = await _profileService.getUsernameFromUserId(userId);
    return username ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: _getUsername(widget.user.toUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Loading...');
            } else if (snapshot.hasError) {
              return Text('Error');
            } else if (snapshot.hasData) {
              return Text(snapshot.data ?? 'Unknown');
            } else {
              return Text('Unknown');
            }
          },
        ),
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messageService.getMessagesBetweenUsers(_currentUserId, widget.user.toUserId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                // Filter messages for the current chat
                final messages = snapshot.data!.where((message) => 
                  (message.fromUserId == _currentUserId && message.toUserId == widget.user.toUserId) ||
                  (message.fromUserId == widget.user.toUserId && message.toUserId == _currentUserId)
                ).toList();

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return ChatBubble(
                      message: messages[index],
                      isSender: messages[index].fromUserId == _currentUserId,
                    );
                  },
                );
              },
            ),
          ),
          ChatInputField(controller: _messageController, onSend: _sendMessage),
        ],
      ),
    );
  }
}

// The ChatBubble and ChatInputField classes remain the same as in the previous implementation
class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isSender;

  const ChatBubble({Key? key, required this.message, required this.isSender}) : super(key: key);

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isSender 
          ? CrossAxisAlignment.end 
          : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: isSender ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.message, 
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
                SizedBox(height: 4),
                Text(
                  _formatTimestamp(message.timeStamp),
                  style: TextStyle(
                    fontSize: 10, 
                    color: Colors.black54
                  ),
                ),
              ],
            ),
          ),
          if (message.status != 'sent')
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                message.status,
                style: TextStyle(
                  fontSize: 10, 
                  color: Colors.black54
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInputField({Key? key, required this.controller, required this.onSend}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: TextStyle(color: Colors.black54),
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.black45),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          SizedBox(width: 10),
          GestureDetector(
            onTap: onSend,
            child: CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}