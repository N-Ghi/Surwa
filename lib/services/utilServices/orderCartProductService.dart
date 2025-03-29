import 'dart:ffi';

import 'package:surwa/data/models/cart.dart';
import 'package:surwa/data/models/order.dart';
import 'package:surwa/data/models/payment.dart';
import 'package:surwa/data/models/product.dart';
import 'package:surwa/services/cart_service.dart';
import 'package:surwa/services/order_service.dart';
import 'package:surwa/services/payment_service.dart';
import 'package:surwa/services/product_service.dart';

class OrderCartService {
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();
  final CartService _cartService = CartService();
  final PaymentService _paymentService = PaymentService();

  Future<void> addOrderAndUpdateCart(OrderClass order) async {
    try {
      final Product product = await _productService.getProductById(order.productId);

      if (product.inStock < order.quantity) {
        return Future.error("Not enough instock");
      }
      final int price = int.parse(product.price) * order.quantity;
      order.price =  price.toString();
      final int inStock = product.inStock;
     
      await _productService.updateProduct(
        order.productId,
        inStock - order.quantity,
      );

      // Step 3: Create the new order
      final String orderId = await _orderService.addOrder(order);
    

      // Step 4: Add the order to the cart or create a new cart if pending
      await _cartService.createOrUpdateCart(order.userId, orderId, order.price);

      print("Order added successfully!");
    } catch (e) {
      print("Error adding order: $e");
    }
  }
  Future<void> makePayment(Payment payment) async {
    try{
      final Cart cart = await _cartService.getCartById(payment.cartId);
      double paidAmount = double.parse(payment.paymentAmount);
      double cartAmount = double.parse(cart.totalPrice);
      print("amounts ${paidAmount} and ${cartAmount}");
      if(paidAmount != cartAmount){
        return Future.error("Paid amount not equal to amount required"); 
      }
      print("making progress");
      await _paymentService.addPayment(payment);
      await _cartService.payCart(payment.cartId);
    }
    catch(e){
      print("Error making payment: $e");
    }
  }
}
