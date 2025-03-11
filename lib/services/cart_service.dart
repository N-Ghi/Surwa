import 'package:cloud_firestore/cloud_firestore.dart';

class CartService {
  final CollectionReference cartCollection =
      FirebaseFirestore.instance.collection('Cart');

  // CREATE: Add a new Cart
  Future<void> addCart(String buyerId, List<String> orderIds, String totalPrice) {
    return cartCollection.add({
      'buyerId': buyerId,
      'orderIds': orderIds, // List of Order IDs
      'totalPrice': totalPrice,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // READ: Fetch all Carts
  Stream<QuerySnapshot> getCarts() {
    return cartCollection.orderBy('timestamp', descending: true).snapshots();
  }

  // READ: Get a Cart by ID
  Future<DocumentSnapshot> getCartById(String cartId) {
    return cartCollection.doc(cartId).get();
  }

  // READ: Get Cart by Buyer ID
  Stream<QuerySnapshot> getCartByBuyerId(String buyerId) {
    return cartCollection.where('buyerId', isEqualTo: buyerId).snapshots();
  }

  // UPDATE: Update a Cart (e.g., update order list or total price)
  Future<void> updateCart(String cartId, List<String> newOrderIds, String newTotalPrice) {
    return cartCollection.doc(cartId).update({
      'orderIds': newOrderIds,
      'totalPrice': newTotalPrice,
    });
  }

  // DELETE: Remove a Cart
  Future<void> deleteCart(String cartId) {
    return cartCollection.doc(cartId).delete();
  }
}
