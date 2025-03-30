import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/message.dart';
import 'package:surwa/services/id_randomizer.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatId(String senderID, String receiverID) {
    return senderID.compareTo(receiverID) > 0 
      ? '$senderID-$receiverID' 
      : '$receiverID-$senderID';
  }

  // Add a message to the database
  Future<bool> addMessage(Message message) async {
    final chatId = getChatId(message.senderID, message.receiverID);
    final String messageID = message.messageID.isEmpty 
          ? generateRandomId()
          : message.messageID;

    try {
      // Ensure the chat document exists with the correct participants
      await _firestore.collection('chats').doc(chatId).set({
        'Participants': [message.senderID, message.receiverID],
        'LastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));  // Using merge to avoid overwriting existing data
      
      // Add the message to the messages subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageID)  // Use the message's ID as the document ID
          .set(message.toMap());   // Using set instead of add to respect the messageID
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Get messages between two users
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
  
  // Get all messages
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
  
  // Get all chats for a user
  Stream<List<Message>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)  // Only get chats where user is a participant
        .snapshots()
        .asyncMap((snapshot) async {
      List<Message> latestMessages = [];

      for (var doc in snapshot.docs) {
        var chatId = doc.id;
        // Get the last message in this chat regardless of sender/receiver
        var lastMessageSnapshot = await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('DateCreated', descending: true)
            .limit(1)
            .get();

        if (lastMessageSnapshot.docs.isNotEmpty) {
          var messageData = lastMessageSnapshot.docs.first.data();
          // Add chat ID to the message data for reference
          messageData['chatId'] = chatId;
          latestMessages.add(Message.fromMap(messageData));
        } else {
          print('No messages found for chat $chatId');
        }
      }
      return latestMessages;
    });
  }

  // Update message status
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
      return false;
    }
  }

  // Delete a message
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
      return false;
    }
  }

  // Get recent messages
  Stream<List<Message>> getRecentMessages(String currentUserId) {
    return _firestore
        .collection('chats')
        .where('Participants', arrayContains: currentUserId)
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

// Function to get chat previews for the UI
  Stream<List<ChatPreview>> getUserChatPreviews(String userId) {
    return _firestore
        .collection('chats')
        .where('Participants', arrayContains: userId)
        .orderBy('LastUpdated', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<ChatPreview> chatPreviews = [];

      for (var doc in snapshot.docs) {
        var chatId = doc.id;
        var chatData = doc.data();
        List<String> participants = List<String>.from(chatData['Participants'] ?? []);
        Timestamp lastUpdated = chatData['LastUpdated'] ?? Timestamp.now();
        
        // Get the last message in this chat
        var lastMessageSnapshot = await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('DateCreated', descending: true)
            .limit(1)
            .get();

        Message? lastMessage;
        if (lastMessageSnapshot.docs.isNotEmpty) {
          var messageData = lastMessageSnapshot.docs.first.data();
          lastMessage = Message.fromMap(messageData);
        } else {
          print('No messages found for chat $chatId');
        }
        chatPreviews.add(ChatPreview(
          chatId: chatId,
          participants: participants,
          lastMessage: lastMessage,
          lastUpdated: lastUpdated,
        ));
      }
      return chatPreviews;
    });
  }
}
