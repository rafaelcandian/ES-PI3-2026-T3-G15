import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    // inicia verificação do usuário assim que a tela abre
    _checkUser();
  }

  // função responsável por decidir para onde o usuário vai
  void _checkUser() async {

    // pequeno delay só para exibir splash visual (UX)
    await Future.delayed(const Duration(seconds: 2));

    // evita erro se a tela for destruída durante o carregamento
    if (!mounted) return;

    // pega usuário atual do Firebase Authentication
    User? user = FirebaseAuth.instance.currentUser;

    // se existir usuário logado → entra direto no sistema
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/catalogo');
    }

    // se não existir usuário logado → vai para login
    else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {

    // tela inicial simples de carregamento
    return Scaffold(
      backgroundColor: AppColors.fundo,

      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: const [

            // ícone do app (identidade visual)
            Icon(
              Icons.monetization_on,
              size: 80,
              color: Colors.yellow,
            ),

            SizedBox(height: 20),

            // indicador de carregamento (feedback visual)
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}