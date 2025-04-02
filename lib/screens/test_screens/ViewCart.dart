import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:surwa/data/constants/cartStatus.dart';
import 'package:surwa/data/models/cart.dart';
import 'package:surwa/screens/test_screens/AddPayment.dart';
import 'package:surwa/services/cart_service.dart';

class CartPage extends StatelessWidget {
  CartPage({super.key});
  
  final CartService _cartService = CartService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Cart",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Cart>>(
        stream: _cartService.getCartByBuyerId(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading cart",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text("${snapshot.error}"),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "Your cart is empty",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Continue Shopping"),
                  ),
                ],
              ),
            );
          }

          final carts = snapshot.data!;
          
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: carts.length,
                  itemBuilder: (context, index) {
                    final cart = carts[index];
                    return CartCard(cart: cart);
                  },
                ),
              ),
              if (carts.any((cart) => cart.status.name == Cartstatus.PENDING.name))
                _buildCheckoutButton(context, carts),
            ],
          );
        },
      ),
    );
  }


Widget _buildCheckoutButton(BuildContext context, List<Cart> carts) {
    final pendingCarts = carts.where((cart) => cart.status.name == Cartstatus.PENDING.name).toList();
    double totalAmount = 0.0;
    
    for (var cart in pendingCarts) {
      try {
        // Check if totalPrice is String or double
        if (cart.totalPrice is String) {
          totalAmount += double.tryParse(cart.totalPrice.toString()) ?? 0.0;
        } else if (cart.totalPrice is double) {
          totalAmount += double.parse(cart.totalPrice);
        } else if (cart.totalPrice is int) {
          totalAmount += double.parse(cart.totalPrice);
        }
      } catch (e) {
        print("Error calculating totalPrice: $e for cart ${cart.cartId}");
      }
    }
    
    // Debug print
    print("Total amount calculated: $totalAmount");
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Total Amount",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
          "${totalAmount.toStringAsFixed(2)}rwf",
          // ...
        ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (pendingCarts.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPaymentPage(cartId: pendingCarts.first.cartId),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Proceed to Checkout",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  
  }
}


class CartCard extends StatelessWidget {
  final Cart cart;

  const CartCard({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    final isPending = cart.status.name == Cartstatus.PENDING.name;
    final formattedDate = _formatDateTime(DateTime.parse(cart.timeStamp));    
    Color statusColor;
    IconData statusIcon;
    
    switch (cart.status.name) {
      case 'PENDING':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        break;
      case 'COMPLETED':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPending
            ? BorderSide(color: Theme.of(context).primaryColor, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isPending
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPaymentPage(cartId: cart.cartId),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Cart #${cart.cartId.substring(0, 8)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          cart.status.name.capitalize(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow(Icons.shopping_bag, "${cart.orderIds.length} items"),
              _buildInfoRow(Icons.attach_money, "${
                (cart.totalPrice is String) 
                    ? (double.tryParse(cart.totalPrice.toString()) ?? 0.0).toStringAsFixed(2)
                    : (cart.totalPrice is double)
                        ? cart.totalPrice.toStringAsFixed(2)
                        : "0.00"
              }rwf"),
              _buildInfoRow(Icons.access_time, formattedDate),
              if (isPending) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddPaymentPage(cartId: cart.cartId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text("Pay Now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('MMM dd, yyyy • hh:mm a');
    return formatter.format(dateTime);
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
  
  toStringAsFixed(int i) {}
}