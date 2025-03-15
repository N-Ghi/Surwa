import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/order.dart';

class OrderService {
  final CollectionReference orderCollection =
      FirebaseFirestore.instance.collection('Order');

  // CREATE: Add a new Order
  Future<void> addOrder(OrderClass order) async {
    await orderCollection.add({
      'productId': order.productId,
      'userId': order.userId,
      'quantity': order.quantity,
      'price': order.price,
      'orderStatus': order.orderStatus,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // READ: Fetch all Orders
  Stream<List<OrderClass>> getOrders() {
    return orderCollection.orderBy('timestamp', descending: true).snapshots().map(
       (QuerySnapshot snapshot){
       return snapshot.docs.map(
        (doc){
          return OrderClass.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }
       ).toList();
      }
    );
  }

  // READ: Get an Order by ID
  Future<OrderClass> getOrderById(String orderId) async{
    DocumentSnapshot doc = await orderCollection.doc(orderId).get();
    return OrderClass.fromFirestore(doc.data() as Map<String,dynamic>, doc.id);
  }
  // READ: Get Orders by User ID
  Stream<List<OrderClass>> getOrdersByUserId(String userId) {
    return orderCollection.where('userId', isEqualTo: userId).orderBy('timestamp', descending: true).snapshots().map(
       (QuerySnapshot snapshot){
       return snapshot.docs.map(
        (doc){
          return OrderClass.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }
       ).toList();
      }
    );
  }
  // UPDATE: Update an Order (e.g. change status, quantity)
  Future<void> updateOrder(String orderId, String newProductId, int newQuantity, String newPrice, String newOrderStatus) {
    return orderCollection.doc(orderId).update({
      'productId': newProductId,
      'quantity': newQuantity,
      'price': newPrice,
      'orderStatus': newOrderStatus,
      'timeStamp': FieldValue.serverTimestamp()
    });
  }

  // DELETE: Remove an Order
  Future<void> deleteOrder(String orderId) {
    return orderCollection.doc(orderId).delete();
  }
}
