import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final CollectionReference orderCollection =
      FirebaseFirestore.instance.collection('Order');

  // CREATE: Add a new Order
  Future<void> addOrder(String productId, String userId, int quantity, String price, String orderStatus, String timeStamp) {
    return orderCollection.add({
      'productId': productId,
      'userId': userId,
      'quantity': quantity,
      'price': price,
      'orderStatus': orderStatus,
      'timeStamp': timeStamp,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // READ: Fetch all Orders
  Stream<QuerySnapshot> getOrders() {
    return orderCollection.orderBy('timestamp', descending: true).snapshots();
  }

  // READ: Get an Order by ID
  Future<DocumentSnapshot> getOrderById(String orderId) {
    return orderCollection.doc(orderId).get();
  }
  // READ: Get Orders by User ID
  Stream<QuerySnapshot> getOrdersByUserId(String userId) {
    return orderCollection.where('userId', isEqualTo: userId).orderBy('timestamp', descending: true).snapshots();
  }
  // UPDATE: Update an Order (e.g. change status, quantity)
  Future<void> updateOrder(String orderId, String newProductId, String newUserId, int newQuantity, String newPrice, String newOrderStatus, String newTimeStamp) {
    return orderCollection.doc(orderId).update({
      'productId': newProductId,
      'userId': newUserId,
      'quantity': newQuantity,
      'price': newPrice,
      'orderStatus': newOrderStatus,
      'timeStamp': newTimeStamp,
    });
  }

  // DELETE: Remove an Order
  Future<void> deleteOrder(String orderId) {
    return orderCollection.doc(orderId).delete();
  }
}
