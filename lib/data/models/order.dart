class OrderClass {
  final String orderId;
  final String productId;
  final String userId;
  final int quantity;
  final String price;
  final String orderStatus;
  final String timeStamp;

  OrderClass({
    required this.orderId,
    required this.productId,
    required this.userId,
    required this.quantity,
    required this.price,
    required this.orderStatus,
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
      orderStatus: data['orderStatus'] ?? '',
      timeStamp: data['timeStamp'] ?? '',
    );
  }

  // Convert Order Object to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'productID': productId,
      'userId': userId,
      'quantity': quantity,
      'price': price,
      'orderStatus': orderStatus,
      'timeStamp': timeStamp,
    };
  }
}
