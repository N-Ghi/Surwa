class ProductDTO {
  final String productId;
  final String name;
  final String price;
  final String imageUrl;
  final String description;
  final String category;
  final int quantity;

  ProductDTO({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.quantity
  });
}