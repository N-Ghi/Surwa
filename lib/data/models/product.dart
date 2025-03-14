class Product {
  final String productId;
  final String ownerId;
  final String name;
  final String price;
  final String category;
  String imageUrl;
  final int inStock;

  Product({
    required this.productId,
    required this.ownerId,
    required this.name,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.inStock,
  });

  // Convert Firestore DocumentSnapshot to Product Object
  factory Product.fromFirestore(Map<String, dynamic> data, String docId) {
    return Product(
      productId: docId,
      ownerId: data['ownerId'],
      name: data['Name'] ?? '',
      price: data['price'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      inStock: int.tryParse(data['inStock'].toString()) ?? 0,
    );
  }

  // Convert Product Object to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'inStock': inStock,
      'ownerId': ownerId,
    };
  }
}
