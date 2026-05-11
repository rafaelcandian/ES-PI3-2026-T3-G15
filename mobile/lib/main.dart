import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mescla_invest/themes/theme_controller.dart';

import 'themes/app_theme.dart';
import 'firebase_options.dart';

import 'package:mescla_invest/themes/theme_controller.dart';

import 'package:mescla_invest/screens/auth/splash_screen.dart';
import 'package:mescla_invest/screens/auth/login_screen.dart';
import 'package:mescla_invest/screens/auth/cadastro_screen.dart';
import 'package:mescla_invest/screens/auth/recuperacao_senha_screen.dart';
import 'package:mescla_invest/screens/startups/catalogo_screen.dart';
import 'package:mescla_invest/screens/startups/detalhes_screen.dart';
import 'package:mescla_invest/screens/dashboard_screen.dart';

import 'package:mescla_invest/screens/testes/balcao_teste_screen.dart';
import 'package:mescla_invest/screens/carteira/carteira_screen.dart';
import 'package:mescla_invest/screens/startups/perfil_screen.dart';
import 'package:mescla_invest/screens/startups/balcao_negociacoes_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MesclaInvestApp());
}

class MesclaInvestApp extends StatelessWidget {
  const MesclaInvestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppAppearanceMode>(
      valueListenable: ThemeController.appearanceMode,
      builder: (context, appearanceMode, _) {
        return MaterialApp(
          title: 'MesclaInvest',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeController.themeMode,
          theme: AppTheme.temaClaro,
          darkTheme: AppTheme.temaPrincipal,
          initialRoute: "/",
          routes: {
            "/": (context) => const SplashScreen(),
            "/login": (context) => const LoginTela(),
            "/cadastro": (context) => const CadastroPage(),
            "/recuperacao_senha": (context) => const RecuperacaoSenhaTela(),
            "/catalogo": (context) => const CatalogoStartupsPage(),
            "/detalhes": (context) => const DetalhesStartupPage(),
            "/dashboard": (context) => const DashboardPage(),
            '/balcao-teste': (context) => const BalcaoTesteScreen(),
            '/balcao': (context) => const BalcaoDeNegociacoesScreen(),
            '/home': (context) => const CatalogoStartupsPage(),
            '/wallet': (context) => const CarteiraPage(),
            '/carteira': (context) => const CarteiraPage(),
            '/perfil': (context) => const PerfilPage(),
          },
        );
      },
    );
  }
}