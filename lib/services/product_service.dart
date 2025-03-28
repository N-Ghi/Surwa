import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/product.dart';
import 'package:surwa/services/image_picker_service.dart';

class ProductService {
  final CollectionReference productCollection =
      FirebaseFirestore.instance.collection('Product');

  // CREATE: Add a Product with ownerId
  Future<DocumentReference<Object?>> addProduct(Product product, File ? imageFile) async {
    print("New product");
    
     if (imageFile != null) {
        print("New product 2");
        final imagePickerService = ImagePickerService();
       
        // Upload the image and get the URL
        String? imageUrl = await imagePickerService.uploadPostImage(imageFile, 'products/${product.ownerId}/${product.productId}');
        print("Image URL after upload: $imageUrl");

        // Explicitly assign the image URL if it's not null
        if (imageUrl != null) {
          product.imageUrl = imageUrl;
           // Make sure to assign it
        }

      } 
     return await productCollection.add({
      'ownerId': product.ownerId, // Store the owner's ID
      'name': product.name,
      'price': product.price,
      'category': product.category,
      'imageUrl': product.imageUrl,
      'inStock': product.inStock,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // READ: Fetch all Products
  Stream<List<Product>> getProducts() {
    return productCollection.orderBy('timestamp', descending: true).snapshots().map(
      (QuerySnapshot snapshot){
       return snapshot.docs.map(
        (doc){
          return Product.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }
       ).toList();
      }
    );
  }

  // READ: Get a Product by ID
  Future<Product> getProductById(String docId) async {
    DocumentSnapshot doc = await productCollection.doc(docId).get();
    return Product.fromFirestore(doc.data() as Map<String,dynamic>, doc.id);
  }

  // READ: Get All Products by a Specific User (ownerId)
  Stream<List<Product>> getProductsByUser(String ownerId) {
    return productCollection.where('ownerId', isEqualTo: ownerId).snapshots().map(
      (QuerySnapshot snapshot){
       return snapshot.docs.map(
        (doc){
          return Product.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }
       ).toList();
      }
    );
  }

  // UPDATE: Update a Product
  Future<void> updateProduct (String docId, String newName, String newPrice, String newCategory, String newImageUrl, int newStock) async {
    return await productCollection.doc(docId).update({
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
