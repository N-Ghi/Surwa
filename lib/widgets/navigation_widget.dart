import 'package:flutter/material.dart';
import 'package:surwa/screens/feeds.dart';
import 'package:surwa/screens/market.dart';
import 'package:surwa/screens/message.dart';
import 'package:surwa/screens/profile.dart';

class NavbarWidget extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavbarWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<NavbarWidget> createState() => _NavbarWidgetState();
}

class _NavbarWidgetState extends State<NavbarWidget> {
  int _selectedIndex = 0;

void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Handle navigation based on the selected index using named routes
    switch (index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => MarketScreen()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (context) => MessagesScreen()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      onTap: _onBottomNavTap,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_basket),
          label: 'Market',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
      ],
    );
  }
}