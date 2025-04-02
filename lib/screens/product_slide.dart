import 'dart:async';
import 'package:flutter/material.dart';

class ProductSlideshow extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Duration slideDuration;
  
  const ProductSlideshow({
    Key? key, 
    required this.products,
    this.slideDuration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<ProductSlideshow> createState() => _ProductSlideshowState();
}

class _ProductSlideshowState extends State<ProductSlideshow> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(widget.slideDuration, (timer) {
      if (_currentPage < widget.products.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.green[600],
        borderRadius: BorderRadius.circular(12),
      ),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: widget.products.length,
        itemBuilder: (context, index) {
          final product = widget.products[index];
          return Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    product['image'],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['description'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Wrap the row with a limited width
                      SizedBox(
                        height: 12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Limit the number of visible dots if there are many products
                            for (int i = 0; i < min(widget.products.length, 10); i++)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == _currentPage ? Colors.white : Colors.white38,
                                ),
                              ),
                            // Show "..." if there are more products than displayed dots
                            if (widget.products.length > 10)
                              const Text(
                                "...",
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8), // Add some padding at the end
            ],
          );
        },
      ),
    );
  }
}

// Helper function to get the minimum of two values
int min(int a, int b) {
  return a < b ? a : b;
}