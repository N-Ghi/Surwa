import 'package:flutter/material.dart';
import 'package:surwa/data/DTOs/ProductDTO.dart';
import 'package:surwa/screens/shoppingcart.dart';
// ignore: unused_import
import 'package:surwa/screens/test_screens/PlaceOrder.dart';

class SingleProductPage extends StatelessWidget {
  final ProductDTO product;

  const SingleProductPage({super.key, required this.product});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShoppingCartPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              '${product.price} Frw',
              style: TextStyle(fontSize: 20, color: Colors.green , fontWeight: FontWeight.bold),
            ),
           SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.network(
                    product.imageUrl,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                  ),
                ),
            SizedBox(height: 10),
           Column(
                  children: List.generate(3, (index) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Image.network(product.imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: product.quantity > 0 ? () {} : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Buy'),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                TabButton(label: "Description", isSelected: true),
                TabButton(label: "Reviews"),
                TabButton(label: "Related products"),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Hand Made Basket',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(product.description),
            Text(
              'wow this is a good product',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(product.reviews ?? '')
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.green,
        unselectedItemColor: const Color.fromARGB(255, 153, 151, 151),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Feed"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Market"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Account"),
        ],
      ),
    );
  }
}

class TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;

  const TabButton({super.key, required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.black : Colors.grey,
        ),
      ),
    );
  }
}