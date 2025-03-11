import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  final CollectionReference paymentCollection =
      FirebaseFirestore.instance.collection('Payment');

  // CREATE: Add a new Payment
  Future<void> addPayment(String payerId, String orderId, String paymentAmount, String timeStamp, String transactionRefNo) {
    return paymentCollection.add({
      'payerId': payerId,
      'orderId': orderId,
      'paymentAmount': paymentAmount,
      'timeStamp': timeStamp,
      'transactionRefNo': transactionRefNo,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // READ: Fetch all Payments
  Stream<QuerySnapshot> getPayments() {
    return paymentCollection.orderBy('timestamp', descending: true).snapshots();
  }

  // READ: Get a Payment by ID
  Future<DocumentSnapshot> getPaymentById(String paymentId) {
    return paymentCollection.doc(paymentId).get();
  }

  // READ: Get Payments by Payer ID
  Stream<QuerySnapshot> getPaymentsByPayerId(String payerId) {
    return paymentCollection.where('payerId', isEqualTo: payerId).snapshots();
  }

  // UPDATE: Update a Payment (e.g., update amount or timestamp)
  Future<void> updatePayment(String paymentId, String newPayerId, String newOrderId, String newPaymentAmount, String newTimeStamp, String newTransactionRefNo) {
    return paymentCollection.doc(paymentId).update({
      'payerId': newPayerId,
      'orderId': newOrderId,
      'paymentAmount': newPaymentAmount,
      'timeStamp': newTimeStamp,
      'transactionRefNo': newTransactionRefNo,
    });
  }

  // DELETE: Remove a Payment
  Future<void> deletePayment(String paymentId) {
    return paymentCollection.doc(paymentId).delete();
  }
}
