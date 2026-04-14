import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/services/autenticacao.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _circleController;
  late AnimationController _cryptoController;
  late Animation<double> _circleAnimation;
  late Animation<Offset> _cryptoAnimation;

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3)); // Simula um tempo de carregamento

    if (!mounted) return;

    if (AuthService().currentUser != null) {
      // Usuário logado, vai para o catálogo
      Navigator.pushReplacementNamed(context, '/catalogo');
    } else {
      // Usuário não logado, vai para a tela de login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 50,
          child: SlideTransition(
            position: _cryptoAnimation,
            child: AnimatedBuilder(
              animation: _cryptoController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _cryptoController.value * 2 * 3.14,
                  child: Icon(
                    Icons.monetization_on, // Ícone para criptomoeda
                    size: 50,
                    color: Colors.yellow,
                  ),
                );
              },
            ),
          ),
        ),
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _circleController.dispose();
    _cryptoController.dispose();
    super.dispose();
  }
}