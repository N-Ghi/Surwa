import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:surwa/data/models/message.dart';
import 'package:surwa/screens/chat_screen.dart';
import 'package:surwa/services/message_service.dart';
import 'package:surwa/services/profile_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ProfileService _profileService = ProfileService();
  final MessageService _messageService = MessageService();
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
            onPressed: () {
              // Implement search functionality
            },
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
                stream: _messageService.getRecentMessages(_currentUserId),
                builder: (context, snapshot) {
                  int unreadCount = snapshot.hasData
                      ? snapshot.data!.where((message) => 
                          message.receiverID == _currentUserId && 
                          message.status != MessageStatus.read).length
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

  Widget _buildEmptyStateWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start a conversation with your friends',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.green,
          ),
          SizedBox(height: 16),
          Text(
            'Loading messages...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllMessagesList() {
    return StreamBuilder<List<Message>>(
      stream: _messageService.getRecentMessages(_currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyStateWidget();
        }

        // Group messages by unique conversation partners
        Map<String, Message> uniqueConversations = {};
        for (var message in snapshot.data!) {
          String otherUserId = message.senderID == _currentUserId 
              ? message.receiverID 
              : message.senderID;
          
          uniqueConversations[otherUserId] = message;
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
                    lastMessage: lastMessage.content,
                    time: _formatTime(lastMessage.dateCreated),
                    isUnread: lastMessage.receiverID == _currentUserId && 
                            lastMessage.status != MessageStatus.read,
                  ),
                  onTap: () {
                    _markMessagesAsRead(otherUserId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          user: Message(
                            messageID: '',
                            senderID: _currentUserId,
                            receiverID: otherUserId,
                            content: '',
                            status: MessageStatus.sent,
                            dateCreated: Timestamp.now(),
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
      stream: _messageService.getRecentMessages(_currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }

        if (!snapshot.hasData) {
          return _buildEmptyStateWidget();
        }

        // Filter unread messages
        List<Message> unreadMessages = snapshot.data!.where((message) => 
          message.receiverID == _currentUserId && 
          message.status != MessageStatus.read
        ).toList();

        if (unreadMessages.isEmpty) {
          return _buildEmptyStateWidget();
        }

        // Group unread messages by sender
        Map<String, Message> uniqueUnreadConversations = {};
        for (var message in unreadMessages) {
          uniqueUnreadConversations[message.senderID] = message;
        }

        return ListView.builder(
          itemCount: uniqueUnreadConversations.length,
          itemBuilder: (context, index) {
            String otherUserId = uniqueUnreadConversations.keys.elementAt(index);
            Message lastMessage = uniqueUnreadConversations[otherUserId]!;
            
            return FutureBuilder<String?>(
              future: _profileService.getUsernameFromUserId(otherUserId),
              builder: (context, usernameSnapshot) {
                return MessageUserTile(
                  user: MessageUser(
                    name: usernameSnapshot.data ?? 'Unknown User',
                    lastMessage: lastMessage.content,
                    time: _formatTime(lastMessage.dateCreated),
                    isUnread: true,
                  ),
                  onTap: () {
                    _markMessagesAsRead(otherUserId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          user: Message(
                            messageID: '',
                            senderID: _currentUserId,
                            receiverID: otherUserId,
                            content: '',
                            status: MessageStatus.sent,
                            dateCreated: Timestamp.now(),
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
  String _formatTime(Timestamp timestamp) {
    try {
      DateTime dateTime = timestamp.toDate();
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error formatting timestamp: $timestamp');
      return '';
    }
  }

  // Method to mark messages as read
  Future<void> _markMessagesAsRead(String otherUserId) async {
    // Get the chat ID
    final chatId = _messageService.getChatId(_currentUserId, otherUserId);
    
    // Fetch messages for this chat
    final messages = await _messageService
        .getMessagesBetweenUsers(_currentUserId, otherUserId)
        .first;
    
    // Update status for unread messages
    for (var message in messages) {
      if (message.receiverID == _currentUserId && message.status != MessageStatus.read) {
        await _messageService.updateMessageStatus(
          chatId: chatId, 
          messageId: message.messageID, 
          newStatus: MessageStatus.read
        );
      }
    }
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