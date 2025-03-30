import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:surwa/data/constants/cartStatus.dart';
import 'package:surwa/data/models/cart.dart';
import 'package:surwa/screens/test_screens/AddPayment.dart';
import 'package:surwa/services/cart_service.dart';

class CartPage extends StatelessWidget {
  CartPage({
    super.key,
  });
  final CartService _cartService = CartService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cart Details")),
      body: StreamBuilder<List<Cart>>(
        stream: _cartService.getCartByBuyerId(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return Center(child: Text("No cart found"));
          }

          final carts = snapshot.data!;

          return ListView.builder(
            itemCount: carts.length,
            itemBuilder: (context, index) {
              final cart = carts[index];
              return CartCard(cart: cart);
            },
          );
        },
      ),
    );
  }
}

class CartCard extends StatelessWidget {
  final Cart cart;

  CartCard({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        title: Text('Cart ID: ${cart.cartId}',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Orders: ${cart.orderIds.length}"),
            Text("Total Price: ${cart.totalPrice}"),
            Text("Status: ${cart.status.name}"),
            Text("Timestamp: ${cart.timeStamp}"),
          ],
        ),
        trailing: Icon(Icons.payment),
        onTap: cart.status.name == Cartstatus.PENDING.name
            ? () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            AddPaymentPage(cartId: cart.cartId)));
              }
            : null,
      ),
    );
  }
}
