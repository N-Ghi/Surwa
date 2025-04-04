import 'package:flutter/material.dart';
import 'package:surwa/data/DTOs/ProductDTO.dart';
import 'package:surwa/data/models/product.dart';
import 'package:surwa/data/models/profile.dart';
import 'package:surwa/screens/create_post.dart';
import 'package:surwa/screens/feeds.dart';
import 'package:surwa/screens/message.dart';
import 'package:surwa/screens/product_slide.dart';
import 'package:surwa/screens/profile.dart';
import 'package:surwa/screens/singleproduct.dart';
import 'package:surwa/screens/test_screens/AddProduct.dart';
import 'package:surwa/screens/test_screens/ViewCart.dart';
import 'package:surwa/services/product_service.dart';
import 'package:surwa/services/profile_service.dart';
import 'package:surwa/widgets/navigation_widget.dart';

class ShoppingCartScreen extends StatelessWidget {
  const ShoppingCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Market', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShoppingCartScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Shopping Cart'),
      ),
    );
  }
}

// ignore: unused_element
class MarketScreen extends StatefulWidget {
  @override
  _MarketScreenState createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 1;  late TabController _tabController;
  final ProductService _productService = ProductService();
  final ProfileService _profileService = ProfileService();
  bool isArtist = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkIfArtist();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _navIndex) return; // Already on this screen
    
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
        break;
      case 1:
      // Already here
        break;
      case 2:
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PostSetup()));
      break;
      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MessagesScreen()));
        break;
      case 4:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
        break;
    }
  }

  Future<void> _checkIfArtist() async {
  try {
    // Get the current user's profile using the existing function
    Profile? userProfile = await _profileService.getLoggedInUserProfile();
    
    // Check if the profile exists and has the artist flag
    if (userProfile != null) {
      if (userProfile.role == 'Artist') {
        setState(() {
          isArtist = true;
        });
        return;
      }
    } else {
      // No profile found, set to false or handle accordingly
      setState(() {
        isArtist = false;
      });
    }
  } catch (e) {
    // Handle any errors
    print('Error checking artist status: $e');
    setState(() {
      isArtist = false;
    });
  }
}
  // List of category items
  final List<Map<String, String>> _categories = [
    {'icon': 'clothing', 'label': 'Clothing'},
    {'icon': 'art', 'label': 'Art'},
    {'icon': 'jewelry', 'label': 'Jewelry'},
    {'icon': 'crafts', 'label': 'Crafts'},
    {'icon': 'shop', 'label': 'Shop'},
  ];

  // List of popular items
  final List<Map<String, dynamic>> _popularItems = [
    {
      'image': 'assets/images/basket.jpg',
      'name': 'Handmade Basket',
      'description': 'Traditional Rwandan woven basket',
      'price': '5,000 Frw',
      'originalPrice': '5,000 Frw',
      'discount': 0,
    },
    {
      'image': 'assets/images/kitenge.jpg',
      'name': 'Igitenge Bag',
      'description': 'Colorful African fabric bag',
      'price': '10,000 Frw',
      'originalPrice': '10,000 Frw',
      'discount': 0,
    },
    {
      'image': 'assets/images/woodcarving.jpg',
      'name': 'Wooden Sculpture',
      'description': 'Hand-carved Imigongo art piece',
      'price': '15,000 Frw',
      'originalPrice': '15,000 Frw',
      'discount': 0,
    },
    {
      'image': 'assets/images/jewelry.jpg',
      'name': 'Beaded Necklace',
      'description': 'Traditional Rwandan jewelry',
      'price': '7,500 Frw',
      'originalPrice': '7,500 Frw',
      'discount': 0,
    },
  ];

  // List of hot deal items (with discounts)
  final List<Map<String, dynamic>> _hotDealItems = [
    {
      'image': 'assets/images/basket.jpg',
      'name': 'Handmade Basket',
      'description': 'Traditional Rwandan woven basket',
      'price': '4,000 Frw',
      'originalPrice': '5,000 Frw',
      'discount': 20,
    },
    {
      'image': 'assets/images/kitenge.jpg',
      'name': 'Igitenge Bag',
      'description': 'Colorful African fabric bag',
      'price': '8,000 Frw',
      'originalPrice': '10,000 Frw',
      'discount': 20,
    },
    {
      'image': 'assets/images/woodcarving.jpg',
      'name': 'Wooden Sculpture',
      'description': 'Hand-carved Imigongo art piece',
      'price': '12,000 Frw',
      'originalPrice': '15,000 Frw',
      'discount': 20,
    },
    {
      'image': 'assets/images/jewelry.jpg',
      'name': 'Beaded Necklace',
      'description': 'Traditional Rwandan jewelry',
      'price': '6,000 Frw',
      'originalPrice': '7,500 Frw',
      'discount': 20,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add Products
                Row(
                  children: [
                    isArtist 
                      ? IconButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => AddProductScreen()));
                          }, 
                          icon: Icon(Icons.add_circle_outline)
                        )
                      : SizedBox(),
                    // Search bar
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            hintText: 'Discover art, culture, and fashion in Rwanda',
                            hintStyle: TextStyle(fontSize: 14),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search),
                            suffixIcon: Icon(Icons.mic),
                          ),
                        ),
                      ),
                    ),
                    IconButton(onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => CartPage()));
                    }, icon: Icon(Icons.shopping_cart_outlined))
                  ],
                ),
                SizedBox(height: 16),

                // Art and Design Banner
                Container(
                  child: ProductSlideshow(
                    products: _popularItems,
                    slideDuration: const Duration(seconds: 4),
                  ),
                ),
                SizedBox(height: 16),
                // Categories
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getIconForCategory(category['label']!),
                                color: Colors.green[800],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              category['label']!,
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 16),

                // Popular Items and Hot Deals Tabs
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(
                        width: 3.0,
                        color: Colors.green,
                      ),
                      insets: EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    labelColor: Colors.green,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                    tabs: [
                      Tab(text: 'Popular Items'),
                      Tab(text: 'Hot Deals'),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // TabBarView for the content
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Popular Items Tab
                      StreamBuilder<List<Product>>(
                          stream: _productService.getProducts(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                  child:
                                      CircularProgressIndicator()); // Loading indicator
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text(
                                      "Error loading products: ${snapshot.error}"));
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return Center(child: Text("No products found"));
                            }
                            List<Product> products = snapshot.data!;
                            return GridView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                final Map<String, dynamic> item = {
                                  'image': product.imageUrl,
                                  'name': product.name,
                                  'description': product.description,
                                  'category': product.category.name,
                                  'price': "${product.price} Frw",
                                  'originalPrice': "${product.price} Frw",
                                  'quantity':product.inStock,
                                  'discount': 0,
                                  'id': product.productId,
                                };
                                return _buildProductCard(item);
                              },
                            );
                          }),

                      // Hot Deals Tab
                      GridView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _hotDealItems.length,
                        itemBuilder: (context, index) {
                          final item = _hotDealItems[index];
                          return _buildProductCard(item, isHotDeal: true);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavbarWidget(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item,
      {bool isHotDeal = false}) {
    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SingleProductPage(
                  product: ProductDTO(
                    productId: item['id'],
                    name: item['name'],
                    price: item['price'],
                    imageUrl: item['image'],
                    description: item['description'],
                    category: item['category'],
                    quantity: item['quantity']
                  ),
                )
              ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: Image.network(
                        item['image'],
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(Icons.image_not_supported,
                                size: 50, color: Colors.grey)),
                      ),
                    ),
                    if (isHotDeal)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${item['discount']}% OFF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      item['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    if (isHotDeal)
                      Text(
                        item['originalPrice'],
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['price'],
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight:
                                isHotDeal ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.shopping_cart,
                            size: 16,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  // Helper method to get icons for categories
  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Clothing':
        return Icons.shopping_bag;
      case 'Art':
        return Icons.palette;
      case 'Jewelry':
        return Icons.diamond;
      case 'Crafts':
        return Icons.handyman;
      case 'Shop':
        return Icons.storefront;
      default:
        return Icons.category;
    }
  }
}
