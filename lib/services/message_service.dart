import 'package:cloud_firestore/cloud_firestore.dart';

class MessageService {
  final CollectionReference messageCollection =
      FirebaseFirestore.instance.collection('Message');

  // CREATE: Add a new Message
  Future<void> addMessage(String fromUserId, String toUserId, String message, String status, String timeStamp) {
    return messageCollection.add({
      'fromUserId': fromUserId,  
      'toUserId': toUserId,      
      'message': message,        
      'status': status,          
      'timeStamp': timeStamp,  
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // READ: Fetch all Messages
  Stream<QuerySnapshot> getMessages() {
    return messageCollection.orderBy('timestamp', descending: true).snapshots();
  }

  // READ: Get a Message by ID
  Future<DocumentSnapshot> getMessageById(String messageId) {
    return messageCollection.doc(messageId).get();
  }

  // READ: Get Messages by From User ID
  Stream<QuerySnapshot> getMessagesByFromUserId(String fromUserId) {
    return messageCollection.where('fromUserId', isEqualTo: fromUserId).snapshots();
  }

  // READ: Get Messages by To User ID
  Stream<QuerySnapshot> getMessagesByToUserId(String toUserId) {
    return messageCollection.where('toUserId', isEqualTo: toUserId).snapshots();
  }

  // UPDATE: Update a Message (e.g., change status)
  Future<void> updateMessage(String messageId, String newStatus) {
    return messageCollection.doc(messageId).update({
      'status': newStatus,  // Change message status (Sent, Read)
    });
  }

  // DELETE: Remove a Message
  Future<void> deleteMessage(String messageId) {
    return messageCollection.doc(messageId).delete();
  }
}
