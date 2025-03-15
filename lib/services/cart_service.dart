import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/cart.dart';
import 'package:surwa/data/models/message.dart';

class CartService {
  final CollectionReference cartCollection =
      FirebaseFirestore.instance.collection('Cart');

  // CREATE: Add a new Cart
  Future<void> addCart(Cart cart) {
    return cartCollection.add({
      'buyerId': cart.buyerId,
      'orderIds': cart.orderIds, // List of Order IDs
      'totalPrice': cart.totalPrice,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // READ: Fetch all Carts
  Stream<List<Cart>> getCarts() {
    return cartCollection.orderBy('timestamp', descending: true).snapshots().map(
       (QuerySnapshot snapshot){
       return snapshot.docs.map(
        (doc){
          return Cart.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }
       ).toList();
      }
    );
  }

  // READ: Get a Cart by ID
  Future<Cart> getCartById(String cartId) async{
    DocumentSnapshot doc = await cartCollection.doc(cartId).get();
    return Cart.fromFirestore(doc.data() as Map<String,dynamic>, doc.id);
  }

  // READ: Get Cart by Buyer ID
  Stream<List<Message>> getCartByBuyerId(String buyerId) {
    return cartCollection.where('buyerId', isEqualTo: buyerId).snapshots().map(
       (QuerySnapshot snapshot){
       return snapshot.docs.map(
        (doc){
          return Message.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }
       ).toList();
      }
    );
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
