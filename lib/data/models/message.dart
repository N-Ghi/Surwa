import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { sent, delivered, read }

class Message {
  final String messageID;
  final String senderID;
  final String receiverID;
  final String content;
  final MessageStatus status;
  final Timestamp dateCreated;

  Message({
    required this.messageID,
    required this.senderID,
    required this.receiverID,
    required this.content,
    required this.status,
    required this.dateCreated,
  });

  // Convert Message object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'MessageID': messageID,
      'SenderID': senderID,
      'ReceiverID': receiverID,
      'Content': content,
      'Status': status.toString().split('.').last, // Store as a string
      'DateCreated': dateCreated,
    };
  }

  // Create a Message object from Firestore data
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      messageID: map['MessageID'] ?? '',
      senderID: map['SenderID'] ?? '',
      receiverID: map['ReceiverID'] ?? '',
      content: map['Content'] ?? '',
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['Status'],
        orElse: () => MessageStatus.sent, // Default status
      ),
      dateCreated: map['DateCreated'] ?? Timestamp.now(),
    );
  }
}

class ChatPreview {
  final String chatId;
  final List<String> participants;
  final Message? lastMessage;
  final Timestamp lastUpdated;

  ChatPreview({
    required this.chatId,
    required this.participants,
    this.lastMessage,
    required this.lastUpdated,
  });
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