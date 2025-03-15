import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/message.dart';

class MessageService {
  final CollectionReference messageCollection =
      FirebaseFirestore.instance.collection('Message');

  // CREATE: Add a new Message
  Future<void> addMessage(Message message) async{
    await messageCollection.add({
      'fromUserId': message.fromUserId,  
      'toUserId': message.toUserId,      
      'message': message.message,        
      'status': message.status,          
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // READ: Fetch all Messages
  Stream<List<Message>> getMessages() {
    return messageCollection.orderBy('timestamp', descending: true).snapshots().map(
       (QuerySnapshot snapshot){
       return snapshot.docs.map(
        (doc){
          return Message.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }
       ).toList();
      }
    );
  }

  // READ: Get a Message by ID
  Future<Message> getMessageById(String messageId) async{
    DocumentSnapshot doc = await messageCollection.doc(messageId).get();
    return Message.fromFirestore(doc.data() as Map<String,dynamic>, doc.id);
  }

  // READ: Get Messages by From User ID
  Stream<List<Message>> getMessagesByFromUserId(String fromUserId) {
    return messageCollection.where('fromUserId', isEqualTo: fromUserId).snapshots().map(
       (QuerySnapshot snapshot){
       return snapshot.docs.map(
        (doc){
          return Message.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }
       ).toList();
      }
    );
  }

  // READ: Get Messages by To User ID
  Stream<List<Message>> getMessagesByToUserId(String toUserId) {
    return messageCollection.where('toUserId', isEqualTo: toUserId).snapshots().map(
       (QuerySnapshot snapshot){
       return snapshot.docs.map(
        (doc){
          return Message.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }
       ).toList();
      }
    );
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
