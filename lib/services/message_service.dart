import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/message.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a unique chatId based on both user IDs
  String _getChatId(String fromUserId, String toUserId) {
    return fromUserId.compareTo(toUserId) > 0 
      ? '$fromUserId-$toUserId' 
      : '$toUserId-$fromUserId';
  }

  // CREATE: Add a new Message to a specific chat
  Future<void> addMessage(Message message) async {
    final chatId = _getChatId(message.fromUserId, message.toUserId);

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toJson());
  }

  // READ: Get messages for a specific chat between two users
  Stream<List<Message>> getMessagesBetweenUsers(String user1Id, String user2Id) {
    final chatId = _getChatId(user1Id, user2Id);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timeStamp', descending: false)
        .snapshots()
        .map((QuerySnapshot snapshot) {
      return snapshot.docs.map((doc) {
        return Message.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // READ: Get all messages across all chats (might be useful for admin or debugging)
  Stream<List<Message>> getAllMessages() {
    return _firestore
        .collectionGroup('messages')
        .orderBy('timeStamp', descending: true)
        .snapshots()
        .map((QuerySnapshot snapshot) {
      return snapshot.docs.map((doc) {
        return Message.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // UPDATE: Update message status (e.g., from 'sent' to 'read')
  Future<void> updateMessageStatus(String chatId, String messageId, String newStatus) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
          'status': newStatus,
        });
  }

  // DELETE: Delete a specific message
  Future<void> deleteMessage(String fromUserId, String toUserId, String messageId) async {
    final chatId = _getChatId(fromUserId, toUserId);

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // GET: Get recent chats for a user
  Stream<List<Map<String, dynamic>>> getRecentChats(String currentUserId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((QuerySnapshot snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'chatId': doc.id,
          'participants': doc['participants'],
          // You might want to add more metadata about the chat
        };
      }).toList();
    });
  }
}