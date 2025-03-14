class Cart {
  final String cartId;
  final String buyerId;
  final List<String> orderIds;
  final String totalPrice;
  final String timeStamp;

  Cart({
    required this.cartId,
    required this.buyerId,
    required this.orderIds,
    required this.totalPrice,
    required this.timeStamp,
  });

  // Convert Firestore DocumentSnapshot to Cart Object
  factory Cart.fromFirestore(Map<String, dynamic> data, String docId) {
    return Cart(
      cartId: docId,
      buyerId: data['buyerId'] ?? '',
      orderIds: List<String>.from(data['orderIds'] ?? []),
      totalPrice: data['totalPrice'] ?? '',
      timeStamp: data['timeStamp'] ?? '',
    );
  }

  // Convert Cart Object to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'buyerId': buyerId,
      'orderIds': orderIds,
      'totalPrice': totalPrice,
      'timeStamp':timeStamp,
    };
  }
}
