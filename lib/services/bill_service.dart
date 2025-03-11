import 'package:cloud_firestore/cloud_firestore.dart';

class BillService {
  final CollectionReference billCollection =
      FirebaseFirestore.instance.collection('Bill');

  // CREATE: Add a new Bill with userId
  Future<void> addBill(String userId, String totalPrice, List<String> items, String timeStamp) {
    return billCollection.add({
      'userId': userId,
      'totalPrice': totalPrice,
      'items': items,  // List of item IDs
      'timeStamp': timeStamp,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // READ: Fetch all Bills
  Stream<QuerySnapshot> getBills() {
    return billCollection.orderBy('timestamp', descending: true).snapshots();
  }

  // READ: Get a Bill by ID
  Future<DocumentSnapshot> getBillById(String billId) {
    return billCollection.doc(billId).get();
  }

  // READ: Get Bills by userId
  Stream<QuerySnapshot> getBillsByUserId(String userId) {
    return billCollection.where('userId', isEqualTo: userId).snapshots();
  }

  // UPDATE: Update a Bill (e.g., change items or total price)
  Future<void> updateBill(String billId, String newTotalPrice, List<String> newItems, String newTimeStamp) {
    return billCollection.doc(billId).update({
      'totalPrice': newTotalPrice,
      'items': newItems,
      'timeStamp': newTimeStamp,
    });
  }

  // DELETE: Remove a Bill
  Future<void> deleteBill(String billId) {
    return billCollection.doc(billId).delete();
  }
}
