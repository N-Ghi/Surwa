import 'package:flutter/material.dart';
import 'package:surwa/screens/create_post.dart';
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
      switch (index) {
        case 0:
          Navigator.push(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
          break;
        case 1:
          Navigator.push(context, MaterialPageRoute(builder: (context) => MarketScreen()));
          break;
        case 2:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PostSetup()),
          );
          break;
        case 3:
          Navigator.push(context, MaterialPageRoute(builder: (context) => MessagesScreen()));
          break;
        case 4:
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
          break;
      }
    }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: widget.currentIndex,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      onTap: _onBottomNavTap,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_basket),
          label: 'Market',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.add_a_photo), label: 'Post', backgroundColor: Colors.green),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
      ],
    );
  }
}