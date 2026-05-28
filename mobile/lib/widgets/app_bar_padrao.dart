import 'package:flutter/material.dart';

class AppBarPadrao extends StatelessWidget implements PreferredSizeWidget {
  final String titulo;

  const AppBarPadrao({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      titleSpacing: 0,
      title: Container(
        margin: const EdgeInsets.only(left: 30),
        alignment: Alignment.centerLeft,
        child: Text(
          titulo,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
