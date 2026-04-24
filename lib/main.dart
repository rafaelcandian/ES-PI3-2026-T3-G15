import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'login_tela.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MesclaInvest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.temaPrincipal,
      home: const LoginTela(),
    );
  }
}