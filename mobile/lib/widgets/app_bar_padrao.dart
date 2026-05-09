import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppBarPadrao extends StatelessWidget implements PreferredSizeWidget {
  final String titulo;

  const AppBarPadrao({
    super.key,
    required this.titulo,
  });

  Future<void> _handleLogout(BuildContext context) async {
    // 🔐 desloga Firebase
    await FirebaseAuth.instance.signOut();

    // 🔁 limpa navegação e volta pro login
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      titleSpacing: 0,
      title: Row(
        children: [
          // Título a esquerda
          Expanded(
            child: Container(
              //espaçamento esquerda
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
          ),

          // Ícone de perfil no canto direito
          PopupMenuButton<String>(
            color: const Color(0xFF182051),
            position: PopupMenuPosition.under,
            onSelected: (String result) {
              if (result == 'logout') {
                _handleLogout(context);
              } else if (result == 'perfil') {
                Navigator.pushNamed(context, '/perfil');
              } else if (result == 'notificacoes') {
                Navigator.pushNamed(context, '/notificacoes');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'notificacoes',
                child: Row(
                  children: [
                    Icon(Icons.notifications_none, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Notificações', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuDivider(color: Color.fromARGB(33, 255, 255, 255)),
              const PopupMenuItem<String>(
                value: 'perfil',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Ver Perfil', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuDivider(color: Color.fromARGB(33, 255, 255, 255)),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sair', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF182051),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}