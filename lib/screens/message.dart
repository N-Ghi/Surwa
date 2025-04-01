import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:surwa/data/models/message.dart';
import 'package:surwa/screens/chat_screen.dart';
import 'package:surwa/screens/feeds.dart';
import 'package:surwa/screens/market.dart';
import 'package:surwa/screens/profile.dart';
import 'package:surwa/services/message_service.dart';
import 'package:surwa/services/profile_service.dart';
import 'package:surwa/widgets/navigation_widget.dart'; // Import the navbar widget

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
  int _navIndex = 2;

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

  void _onNavTap(int index) {
    if (index == _navIndex) return; // Already on this screen
    
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MarketScreen()),
        );
        break;
      case 2:
        // Already on this screen
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
        break;
    }
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
      bottomNavigationBar: NavbarWidget(
        currentIndex: _navIndex,
        onTap: _onNavTap,
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
    return StreamBuilder<List<ChatPreview>>(
    stream: _messageService.getUserChatPreviews(_currentUserId),
    builder: (context, snapshot) {

      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildLoadingWidget();
      }

      // Changed condition to be more explicit
      if (snapshot.hasError) {
        return Center(child: Text("Error loading messages"));
      }
      
      if (!snapshot.hasData) {
        return _buildLoadingWidget(); // Show loading instead if empty
      }
      
      List<ChatPreview> chatPreviews = snapshot.data!;
      
      if (chatPreviews.isEmpty) {
        return _buildEmptyStateWidget();
      }

        return ListView.builder(
          itemCount: chatPreviews.length,
          itemBuilder: (context, index) {
            ChatPreview preview = chatPreviews[index];
            
            // Find the other user ID (not the current user)
            String otherUserId = preview.participants.firstWhere(
              (id) => id != _currentUserId,
              orElse: () => "Unknown", // Fallback in case of group chats or errors
            );

            return FutureBuilder<String?>(
              future: _profileService.getUsernameFromUserId(otherUserId),
              builder: (context, usernameSnapshot) {
                bool isUnread = preview.lastMessage != null && 
                    preview.lastMessage!.receiverID == _currentUserId &&
                    preview.lastMessage!.status != MessageStatus.read;
                
                return MessageUserTile(
                  user: MessageUser(
                    name: usernameSnapshot.data ?? 'Unknown User',
                    lastMessage: preview.lastMessage?.content ?? 'No messages yet',
                    time: preview.lastMessage != null 
                        ? _formatTime(preview.lastMessage!.dateCreated) 
                        : '',
                    isUnread: isUnread,
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
    return StreamBuilder<List<ChatPreview>>(
      stream: _messageService.getUserChatPreviews(_currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyStateWidget();
        }

        // Filter chats with unread messages
        List<ChatPreview> unreadChatPreviews = snapshot.data!.where((preview) {
          return preview.lastMessage != null &&
              preview.lastMessage!.receiverID == _currentUserId &&
              preview.lastMessage!.status != MessageStatus.read;
        }).toList();

        if (unreadChatPreviews.isEmpty) {
          return _buildEmptyStateWidget();
        }

        return ListView.builder(
          itemCount: unreadChatPreviews.length,
          itemBuilder: (context, index) {
            ChatPreview preview = unreadChatPreviews[index];
            
            // Find the other user ID (not the current user)
            String otherUserId = preview.participants.firstWhere(
              (id) => id != _currentUserId,
              orElse: () => "Unknown", // Fallback in case of group chats or errors
            );

            return FutureBuilder<String?>(
              future: _profileService.getUsernameFromUserId(otherUserId),
              builder: (context, usernameSnapshot) {
                return MessageUserTile(
                  user: MessageUser(
                    name: usernameSnapshot.data ?? 'Unknown User',
                    lastMessage: preview.lastMessage?.content ?? '',
                    time: preview.lastMessage != null 
                        ? _formatTime(preview.lastMessage!.dateCreated) 
                        : '',
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
          color: user.isUnread ? Colors.green[300] : Colors.grey,
        ),
      ),
      subtitle: Text(
        user.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: user.isUnread ? Colors.green[300] : Colors.grey,
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