import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:surwa/data/constants/constants.dart';
import 'package:surwa/data/models/payment.dart';
import 'package:surwa/screens/feeds.dart';
import 'package:surwa/screens/test_screens/ViewPaymentsPage.dart';
import 'package:surwa/services/utilServices/orderCartProductService.dart';

class AddPaymentPage extends StatefulWidget {
  final String cartId;

  const AddPaymentPage({super.key, required this.cartId});
  @override
  _AddPaymentPageState createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _paymentAmountController = TextEditingController();
  final OrderCartService _paymentService = OrderCartService();
  final String _payerId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _addPayment() async {
    final payment = Payment(
      paymentId: '',
      payerId: _payerId,
      cartId: widget.cartId,
      paymentAmount: _paymentAmountController.text,
      transactionRefNo: generateTransactionId(),
      timeStamp: DateTime.now().toIso8601String(),
    );

    try {
      await _paymentService.makePayment(payment);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green),
      );
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => DashboardScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Payment"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _paymentAmountController,
              decoration: InputDecoration(labelText: "Payment Amount"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addPayment,
              child: Text("Add Payment"),
            ),
          ],
        ),
      ),
    );
  }
}
