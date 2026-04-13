import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: LoginPage(),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
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

    _circleAnimation = Tween<double>(begin: 0, end: 2 * 3.14).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.linear),
    );

    _cryptoController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _cryptoAnimation = Tween<Offset>(begin: Offset(0, 0), end: Offset(0, -50)).animate(
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