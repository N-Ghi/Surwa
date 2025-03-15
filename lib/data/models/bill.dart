class Bill {
  final String billId;
  final String userId;
  final String totalPrice;
  final List<String> items;
  final String timeStamp;

  Bill({
    required this.billId,
    required this.userId,
    required this.totalPrice,
    required this.items,
    required this.timeStamp,
  });

  // Convert Firestore DocumentSnapshot to Bill Object
  factory Bill.fromFirestore(Map<String, dynamic> data, String docId) {
    return Bill(
      billId: docId,
      userId: data['userId'] ?? '',
      totalPrice: data['totalPrice'] ?? '',
      items: List<String>.from(data['items'] ?? []),
      timeStamp: data['timeStamp'] ?? '',
    );
  }

  // Convert Bill Object to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'totalPrice': totalPrice,
      'items': items,
      'userId':userId,
      'timeStamp': timeStamp,
    };
  }
}
