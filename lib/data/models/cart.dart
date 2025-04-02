import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/constants/cartStatus.dart';

class Cart {
  final String cartId;
  final String buyerId;
  final List<String> orderIds;
  final String totalPrice;
  final Cartstatus status;
  final String timeStamp;

  Cart({
    required this.cartId,
    required this.buyerId,
    required this.orderIds,
    required this.totalPrice,
    required this.status,
    required this.timeStamp,
  });

  // Convert Firestore DocumentSnapshot to Cart Object
  factory Cart.fromFirestore(Map<String, dynamic> data, String docId) {
    return Cart(
      cartId: docId,
      buyerId: data['buyerId'] ?? '',
      orderIds: List<String>.from(data['orderIds'] ?? []),
      totalPrice: data['totalPrice'] ?? '',
      status: parseStatus(data['status']),
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
