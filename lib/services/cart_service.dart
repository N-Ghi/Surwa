import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/constants/cartStatus.dart';
import 'package:surwa/data/models/cart.dart';

class CartService {
  final CollectionReference cartCollection =
      FirebaseFirestore.instance.collection('Cart');
  Future<void> createOrUpdateCart(
      String userId, String orderId, String price) async {
    try {
      // Check if there is a pending cart for this user
      final userCartQuery = await cartCollection
          .where('buyerId', isEqualTo: userId)
          .where('status', isEqualTo: 'PENDING')
          .limit(1)
          .get();

      final timestamp = DateTime.now().toIso8601String();

      if (userCartQuery.docs.isNotEmpty) {
        // Update existing cart
        final cartDoc = userCartQuery.docs.first.reference;
        final List<String> orderIds =
            List<String>.from(userCartQuery.docs.first['orderIds']);
        final double existingTotal =
            double.parse(userCartQuery.docs.first['totalPrice']);

        orderIds.add(orderId);
        final double newTotal = existingTotal + double.parse(price);

        await cartDoc.update({
          'orderIds': orderIds,
          'totalPrice': newTotal.toString(),
        });
      } else {
        // Create new cart
        await cartCollection.add({
          'buyerId': userId,
          'orderIds': [orderId],
          'totalPrice': price,
          'status': Cartstatus.PENDING.name,
          'timeStamp': timestamp,
        });
      }
    } catch (e) {
      print("Error creating or updating cart: $e");
      rethrow;
    }
  }

  // READ: Fetch all Carts
  Stream<List<Cart>> getCarts() {
    return cartCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((QuerySnapshot snapshot) {
      return snapshot.docs.map((doc) {
        return Cart.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // READ: Get a Cart by ID
  Future<Cart> getCartById(String cartId) async {
    DocumentSnapshot doc = await cartCollection.doc(cartId).get();
    return Cart.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
  }

  // READ: Get Cart by Buyer ID
  Stream<List<Cart>> getCartByBuyerId(String buyerId) {
    return cartCollection
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .map((QuerySnapshot snapshot) {
      return snapshot.docs.map((doc) {
        return Cart.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> payCart(String cartId) {
    return cartCollection.doc(cartId).update({'status': Cartstatus.PAID.name});
  }

  // DELETE: Remove a Cart
  Future<void> deleteCart(String cartId) {
    return cartCollection.doc(cartId).delete();
  }
}
