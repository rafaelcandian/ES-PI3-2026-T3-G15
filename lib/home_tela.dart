import 'package:flutter/material.dart';
import 'app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _circleController;
  late AnimationController _cryptoController;
  late Animation<double> _circleAnimation;
  late Animation<Offset> _cryptoAnimation;

  @override
  void initState() {
    super.initState();

    _circleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _circleAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14,
    ).animate(
      CurvedAnimation(
        parent: _circleController,
        curve: Curves.linear,
      ),
    );

    _cryptoController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _cryptoAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(
      CurvedAnimation(
        parent: _cryptoController,
        curve: Curves.easeOut,
      ),
    );

    _cryptoController.forward().then((_) {
      _cryptoController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: Center(
        child: Stack(
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
                      child: const Icon(
                        Icons.monetization_on,
                        size: 50,
                        color: AppColors.destaque,
                      ),
                    );
                  },
                ),
              ),
            ),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.azul,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _circleController.dispose();
    _cryptoController.dispose();
    super.dispose();
  }
}