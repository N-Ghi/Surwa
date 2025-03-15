import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/payment.dart';

class PaymentService {
  final CollectionReference paymentCollection =
      FirebaseFirestore.instance.collection('Payment');

  // CREATE: Add a new Payment
  Future<void> addPayment(Payment payment) async{
    await paymentCollection.add({
      'payerId': payment.payerId,
      'orderId': payment.orderId,
      'paymentAmount': payment.paymentAmount,
      'transactionRefNo': payment.transactionRefNo,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // READ: Fetch all Payments
  Stream<List<Payment>> getPayments(){
    return  paymentCollection.orderBy('timestamp', descending: true).snapshots().map(
       (QuerySnapshot snapshot){
       return snapshot.docs.map(
        (doc){
          return Payment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }
       ).toList();
      }
    );
  }

  // READ: Get a Payment by ID
  Future<Payment> getPaymentById(String paymentId) async{
    DocumentSnapshot doc  =  await paymentCollection.doc(paymentId).get();
    return Payment.fromFirestore(doc.data() as Map<String,dynamic>, doc.id);
  }

  // READ: Get Payments by Payer ID
  Stream<List<Payment>> getPaymentsByPayerId(String payerId) {
    return paymentCollection.where('payerId', isEqualTo: payerId).snapshots().map(
       (QuerySnapshot snapshot){
       return snapshot.docs.map(
        (doc){
          return Payment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }
       ).toList();
      }
    );
  }

  // UPDATE: Update a Payment (e.g., update amount or timestamp)
  Future<void> updatePayment(String paymentId, String newPaymentAmount) async{
    return await paymentCollection.doc(paymentId).update({
      'paymentAmount': newPaymentAmount,
    });
  }

  // DELETE: Remove a Payment
  Future<void> deletePayment(String paymentId) {
    return paymentCollection.doc(paymentId).delete();
  }
}
