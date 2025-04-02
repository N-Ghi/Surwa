import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:surwa/data/constants/constants.dart';
import 'package:surwa/data/models/payment.dart';
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
  bool _isProcessing = false;

  Future<void> _addPayment() async {
    if (_paymentAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a payment amount'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _paymentAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Payment"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.payment_rounded,
                  size: 50,
                  color: theme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _paymentAmountController,
              decoration: InputDecoration(
                labelText: "Enter Amount",
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'\d*\.?\d{0,2}'))],
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Payment Details", style: TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),
                    _buildDetailRow("Transaction ID", generateTransactionId().substring(0, 8)),
                    const SizedBox(height: 10),
                    _buildDetailRow("Cart ID", widget.cartId.length > 8 ? "${widget.cartId.substring(0, 8)}..." : widget.cartId),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isProcessing ? null : _addPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Text("CONFIRM PAYMENT", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewPaymentsPage())),
              child: const Text("View Payment History"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
