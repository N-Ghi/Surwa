class Message {
  final String collectionId;
  final String fromUserId;
  final String toUserId;
  final String message;
  final String status;
  final String timeStamp;

  Message({
    required this.collectionId,
    required this.fromUserId,
    required this.toUserId,
    required this.message,
    required this.status,
    required this.timeStamp,
  });

  // Convert Firestore DocumentSnapshot to Message Object
  factory Message.fromFirestore(Map<String, dynamic> data, String docId) {
    return Message(
      collectionId: docId,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      message: data['message'] ?? '',
      status: data['status'] ?? '',
      timeStamp: data['timeStamp'] ?? '',
    );
  }

  // Convert Message Object to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'message': message,
      'status': status,
      'timeStamp': timeStamp,
    };
  }
}
