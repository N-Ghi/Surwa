import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:surwa/data/models/payment.dart';
import 'package:surwa/services/payment_service.dart';


class ViewPaymentsPage extends StatelessWidget {
  final PaymentService _paymentService = PaymentService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Payments"),
      ),
      body: StreamBuilder<List<Payment>>(
        stream: _paymentService.getPaymentsByPayerId(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final payments = snapshot.data ?? [];

          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  title: Text('Payment ID: ${payment.paymentId}', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Payment Amount: ${payment.paymentAmount}"),
                      Text("Transaction Ref No: ${payment.transactionRefNo}"),
                      Text("Timestamp: ${payment.timeStamp}"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
