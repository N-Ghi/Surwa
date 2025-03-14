import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/bill.dart';

class BillService {
  final CollectionReference billCollection =
      FirebaseFirestore.instance.collection('Bill');

  // CREATE: Add a new Bill with userId
  Future<void> addBill(Bill bill) {
    return billCollection.add({
      'userId': bill.userId,
      'totalPrice': bill.totalPrice,
      'items': bill.items,  // List of item IDs
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // READ: Fetch all Bills
  Stream<List<Bill>> getBills() {
    return billCollection.orderBy('timestamp', descending: true).snapshots().map(
       (QuerySnapshot snapshot){
       return snapshot.docs.map(
        (doc){
          return Bill.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }
       ).toList();
      }
    );
  }

  // READ: Get a Bill by ID
  Future<Bill> getBillById(String billId) async{
    DocumentSnapshot doc = await billCollection.doc(billId).get();
    return Bill.fromFirestore(doc.data() as Map<String,dynamic>, doc.id);
  }

  // READ: Get Bills by userId
  Stream<List<Bill>> getBillsByUserId(String userId) {
    return billCollection.where('userId', isEqualTo: userId).snapshots().map(
       (QuerySnapshot snapshot){
       return snapshot.docs.map(
        (doc){
          return Bill.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }
       ).toList();
      }
    );
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
