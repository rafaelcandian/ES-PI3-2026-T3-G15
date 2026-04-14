import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.rocket), label: 'Startups'),
        BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Wallet'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}