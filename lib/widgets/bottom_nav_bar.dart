import 'package:flutter/material.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 1;

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/catalogo');
        break;
      case 2:
        Navigator.pushNamed(context, '/wallet');
        break;
      case 3:
        Navigator.pushNamed(context, '/dashboard');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,

      backgroundColor: const Color(0xFF070A1E),
      selectedItemColor: const Color(0xFFFFC53D),
      unselectedItemColor: Colors.white54,

      type: BottomNavigationBarType.fixed,

      onTap: _onTap,

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.rocket_launch),
          label: 'Startups',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: 'Wallet',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Dashboard',
        ),
      ],
    );
  }
}