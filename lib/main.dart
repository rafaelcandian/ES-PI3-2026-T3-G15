import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/auth/app_theme.dart';
import 'firebase_options.dart';

import 'package:mescla_invest/screens/auth/splash_screen.dart';
import 'package:mescla_invest/screens/auth/login_screen.dart';
import 'package:mescla_invest/screens/auth/cadastro_screen.dart';
import 'package:mescla_invest/screens/auth/recuperacao_senha_screen.dart';
import 'package:mescla_invest/screens/startups/catalogo_screen.dart';
import 'package:mescla_invest/screens/startups/detalhes_screen.dart';
import 'package:firebase_auth/firebase_auth.dart'; // New import
import 'package:mescla_invest/services/startup_service.dart'; // Import StartupService
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    // Attempt to sign in with email and password
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'guilhermehmoreira12@gmail.com',
      password: 'rob123456',
    );
    print("Logged in successfully with guilhermehmoreira12@gmail.com");

    // Seed initial data if the collection is empty (this will now run after authentication)
    await StartupService().seedStartups();
    print('Startup seeding completed.');

  } on FirebaseAuthException catch (e) {
    print("Firebase Auth Error during login: ${e.code} - ${e.message}");
  } catch (e) {
    print("General Error during login or seeding: $e");
  }

  runApp(const MesclaInvestApp());
}

class MesclaInvestApp extends StatelessWidget {
  const MesclaInvestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MesclaInvest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.temaPrincipal,
      initialRoute: "/",
      routes: {
        "/": (context) => const SplashScreen(),
        "/login": (context) => const LoginTela(),
        "/cadastro": (context) => const CadastroPage(),
        "/recuperacao_senha": (context) => const RecuperacaoSenhaTela(),
        "/catalogo": (context) => const CatalogoStartupsPage(),
        "/detalhes": (context) => const DetalhesStartupPage(),
      },
    );
  }
}
