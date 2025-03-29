class OrderClass {
  final String orderId;
  final String productId;
  final String userId;
  final int quantity;
  String price;
  final String timeStamp;

  OrderClass({
    required this.orderId,
    required this.productId,
    required this.userId,
    required this.quantity,
    required this.price,
    required this.timeStamp,
  });

  // Convert Firestore DocumentSnapshot to Order Object
  factory OrderClass.fromFirestore(Map<String, dynamic> data, String docId) {
    return OrderClass(
      orderId: docId,
      productId: data['productID'] ?? '',
      userId: data['userId'] ?? '',
      quantity: int.tryParse(data['quantity'].toString()) ?? 0,
      price: data['price'] ?? '',
      timeStamp: data['timeStamp'] ?? '',
    );
  }

  // Convert Order Object to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'userId': userId,
      'quantity': quantity,
      'price': price,
      'timeStamp': timeStamp,
    };
  }
}
