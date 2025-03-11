import 'package:cloud_firestore/cloud_firestore.dart';

class ProductService {
  final CollectionReference productCollection =
      FirebaseFirestore.instance.collection('Product');

  // CREATE: Add a Product with ownerId
  Future<void> addProduct(String ownerId, String name, String price, String category, String imageUrl, int inStock) {
    return productCollection.add({
      'ownerId': ownerId, // Store the owner's ID
      'name': name,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'inStock': inStock,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // READ: Fetch all Products
  Stream<QuerySnapshot> getProducts() {
    return productCollection.orderBy('timestamp', descending: true).snapshots();
  }

  // READ: Get a Product by ID
  Future<DocumentSnapshot> getProductById(String docId) {
    return productCollection.doc(docId).get();
  }

  // READ: Get All Products by a Specific User (ownerId)
  Stream<QuerySnapshot> getProductsByUser(String ownerId) {
    return productCollection.where('ownerId', isEqualTo: ownerId).snapshots();
  }

  // UPDATE: Update a Product
  Future<void> updateProduct(String docId, String newName, String newPrice, String newCategory, String newImageUrl, int newStock) {
    return productCollection.doc(docId).update({
      'name': newName,
      'price': newPrice,
      'category': newCategory,
      'imageUrl': newImageUrl,
      'inStock': newStock,
    });
  }

  // DELETE: Remove a Product
  Future<void> deleteProduct(String docId) {
    return productCollection.doc(docId).delete();
  }
}
