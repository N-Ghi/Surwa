import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:surwa/data/models/message.dart';
import 'package:surwa/services/message_service.dart';
import 'package:surwa/services/profile_service.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MessageService _messageService = MessageService();
  final ProfileService _profileService = ProfileService();
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Messages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: [
            Tab(text: 'All'),
            Tab(
              child: StreamBuilder<List<Message>>(
                stream: _messageService.getAllMessages(),
                builder: (context, snapshot) {
                  int unreadCount = snapshot.hasData
                      ? snapshot.data!.where((message) => 
                          message.toUserId == _currentUserId && 
                          message.status != 'read').length
                      : 0;
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Unread'),
                      SizedBox(width: 4),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllMessagesList(),
          _buildUnreadMessagesList(),
        ],
      ),
    );
  }

  Widget _buildAllMessagesList() {
    return StreamBuilder<List<Message>>(
      stream: _messageService.getAllMessages(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        // Group messages by unique conversation partners
        Map<String, Message> uniqueConversations = {};
        for (var message in snapshot.data!) {
          String otherUserId = message.fromUserId == _currentUserId 
              ? message.toUserId 
              : message.fromUserId;
          
          // Keep the most recent message for each conversation
          if (!uniqueConversations.containsKey(otherUserId) || 
              DateTime.parse(message.timeStamp).isAfter(
                DateTime.parse(uniqueConversations[otherUserId]!.timeStamp)
              )) {
            uniqueConversations[otherUserId] = message;
          }
        }

        return ListView.builder(
          itemCount: uniqueConversations.length,
          itemBuilder: (context, index) {
            String otherUserId = uniqueConversations.keys.elementAt(index);
            Message lastMessage = uniqueConversations[otherUserId]!;
            
            return FutureBuilder<String?>(
              future: _profileService.getUsernameFromUserId(otherUserId),
              builder: (context, usernameSnapshot) {
                return MessageUserTile(
                  user: MessageUser(
                    name: usernameSnapshot.data ?? 'Unknown User',
                    lastMessage: lastMessage.message,
                    time: _formatTime(lastMessage.timeStamp),
                    isUnread: lastMessage.toUserId == _currentUserId && 
                            lastMessage.status != 'read',
                  ),
                  onTap: () {
                    // Mark messages as read when conversation is opened
                    _markMessagesAsRead(otherUserId);
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          user: Message(
                            collectionId: '',
                            fromUserId: _currentUserId,
                            toUserId: otherUserId,
                            message: '',
                            status: '',
                            timeStamp: '',
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUnreadMessagesList() {
    return StreamBuilder<List<Message>>(
      stream: _messageService.getAllMessages(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        // Filter unread messages
        List<Message> unreadMessages = snapshot.data!.where((message) => 
          message.toUserId == _currentUserId && 
          message.status != 'read'
        ).toList();

        // Group unread messages by sender
        Map<String, Message> uniqueUnreadConversations = {};
        for (var message in unreadMessages) {
          uniqueUnreadConversations[message.fromUserId] = message;
        }

        return ListView.builder(
          itemCount: uniqueUnreadConversations.length,
          itemBuilder: (context, index) {
            String senderId = uniqueUnreadConversations.keys.elementAt(index);
            Message lastMessage = uniqueUnreadConversations[senderId]!;
            
            return FutureBuilder<String?>(
              future: _profileService.getUsernameFromUserId(senderId),
              builder: (context, usernameSnapshot) {
                return MessageUserTile(
                  user: MessageUser(
                    name: usernameSnapshot.data ?? 'Unknown User',
                    lastMessage: lastMessage.message,
                    time: _formatTime(lastMessage.timeStamp),
                    isUnread: true,
                  ),
                  onTap: () {
                    // Mark messages as read when conversation is opened
                    _markMessagesAsRead(senderId);
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          user: Message(
                            collectionId: '',
                            fromUserId: _currentUserId,
                            toUserId: senderId,
                            message: '',
                            status: '',
                            timeStamp: '',
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // Helper method to format timestamp
  String _formatTime(String timestamp) {
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  // Method to mark messages as read
  Future<void> _markMessagesAsRead(String otherUserId) async {
    // TODO: Implement marking messages as read
    // You might want to update the status of messages in the MessageService
  }
}

class MessageUser {
  final String name;
  final String lastMessage;
  final String time;
  bool isUnread;

  MessageUser({
    required this.name,
    required this.lastMessage,
    required this.time,
    this.isUnread = false,
  });
}

// The MessageUserTile remains the same as in the previous implementation
class MessageUserTile extends StatelessWidget {
  final MessageUser user;
  final VoidCallback onTap;

  const MessageUserTile({Key? key, required this.user, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(0xFFE6E6FA),
        child: Icon(Icons.person_outline, color: Colors.deepPurple),
      ),
      title: Text(
        user.name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: user.isUnread ? Colors.black : Colors.grey,
        ),
      ),
      subtitle: Text(
        user.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: user.isUnread ? Colors.black : Colors.grey,
          fontWeight: user.isUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            user.time,
            style: TextStyle(
              color: user.isUnread ? Colors.green : Colors.grey,
              fontWeight: user.isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (user.isUnread)
            CircleAvatar(
              radius: 8,
              backgroundColor: Colors.green,
              child: Text(
                '1',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}