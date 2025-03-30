import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:surwa/data/models/order.dart';
import 'package:surwa/screens/feeds.dart';
import 'package:surwa/services/utilServices/orderCartProductService.dart';

class OrderPage extends StatefulWidget {
  final String productId;

  OrderPage({required this.productId});

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final OrderCartService _orderService = OrderCartService();
  final TextEditingController _quantityController = TextEditingController();
  final _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = false;

  Future<void> _placeOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      OrderClass order = OrderClass(orderId: "test", productId: widget.productId, userId: _currentUserId, quantity: int.parse(_quantityController.text), price:"0", timeStamp: FieldValue.serverTimestamp().toString());

      await _orderService.addOrderAndUpdateCart(order);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order placed successfully!")),
      );

      // Clear fields
      _quantityController.clear();

      Navigator.push(
          context, MaterialPageRoute(builder: (context) => DashboardScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to place order")),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Place an Order")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Product ID: ${widget.productId}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: "Quantity"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator()) // Show loading indicator
                : ElevatedButton(
                    onPressed: _placeOrder,
                    child: Text("Place Order"),
                  ),
          ],
        ),
      ),
    );
  }
}
