import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/message.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatId(String senderID, String receiverID) {
    return senderID.compareTo(receiverID) > 0 
      ? '$senderID-$receiverID' 
      : '$receiverID-$senderID';
  }

  Future<bool> addMessage(Message message) async {
    final chatId = getChatId(message.senderID, message.receiverID);

    try {
      // First, ensure the chat document exists with the correct participants
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [message.senderID, message.receiverID],
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));  // Using merge to avoid overwriting existing data
      
      // Then add the message to the messages subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());
      return true;
    } catch (e) {
      print('Error adding message: $e');
      return false;
    }
  }
  
  Stream<List<Message>> getMessagesBetweenUsers(String user1Id, String user2Id) {
    final chatId = getChatId(user1Id, user2Id);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('DateCreated', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Message.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Stream<List<Message>> getAllMessages() {
    return _firestore
        .collectionGroup('messages')
        .orderBy('DateCreated', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Message.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'chatId': doc.id,
          'participants': doc['participants'],
        };
      }).toList();
    });
  }

  Future<bool> updateMessageStatus({
    required String chatId, 
    required String messageId, 
    required MessageStatus newStatus,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'Status': newStatus.toString().split('.').last});
      return true;
    } catch (e) {
      print('Error updating message status: $e');
      return false;
    }
  }

  Future<bool> deleteMessage({
    required String senderID, 
    required String receiverID, 
    required String messageID,
  }) async {
    final chatId = getChatId(senderID, receiverID);

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageID)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  Stream<List<Message>> getRecentMessages(String currentUserId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      final recentMessages = <Message>[];
      
      for (var chatDoc in snapshot.docs) {
        final messagesQuery = await chatDoc.reference
            .collection('messages')
            .orderBy('DateCreated', descending: true)
            .limit(1)
            .get();
        
        if (messagesQuery.docs.isNotEmpty) {
          final mostRecentMessage = Message.fromMap(
            messagesQuery.docs.first.data()
          );
          recentMessages.add(mostRecentMessage);
        }
      }
      
      return recentMessages;
    });
  }
}