import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/screens/startups/perfil_screen.dart';

import 'firebase_options.dart';

import 'screens/auth/app_theme.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/cadastro_screen.dart';
import 'screens/auth/recuperacao_senha_screen.dart';

import 'screens/startups/catalogo_screen.dart';
import 'screens/startups/carteira_screen.dart';
import 'screens/startups/balcao_negociacoes_screen.dart';
import 'screens/startups/detalhes_screen.dart';

import 'services/startup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'guilhermehmoreira12@gmail.com',
      password: 'rob123456',
    );

    print("Logado com sucesso com guilhermehmoreira12@gmail.com");

    await StartupService().seedStartups();
    print('Seed de startups completado.');
  } on FirebaseAuthException catch (e) {
    print("Erro de autenticação Firebase: ${e.code} - ${e.message}");
  } catch (e) {
    print("Erro geral durante o login ou seed: $e");
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
        "/cadastro": (context) => const CadastroTela(),
        "/recuperacao_senha": (context) => const RecuperacaoSenhaTela(),

        "/catalogo": (context) => const CatalogoScreen(),
        "/detalhes": (context) => const DetalhesStartupPage(),
        "/balcao": (context) => const BalcaoDeNegociacoesScreen(),
        "/carteira": (context) => const CarteiraPage(),
        "/perfil": (context) => const PerfilPage(),
      },
    );
  }
}