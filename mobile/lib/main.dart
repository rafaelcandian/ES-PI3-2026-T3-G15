/* Victória Nobre - 25016398 */

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:mescla_invest/screens/main_screens/balcao_negociacoes_screen.dart';
import 'package:mescla_invest/screens/main_screens/catalogo_screen.dart';
import 'package:mescla_invest/screens/main_screens/perfil_screen.dart';

import 'themes/app_theme.dart';
import 'firebase_options.dart';

import 'package:mescla_invest/screens/auth/splash_screen.dart';
import 'package:mescla_invest/screens/auth/login_screen.dart';
import 'package:mescla_invest/screens/auth/cadastro_screen.dart';
import 'package:mescla_invest/screens/auth/recuperacao_senha_screen.dart';
import 'package:mescla_invest/screens/auth/verificacao_login_screen.dart';
import 'package:mescla_invest/screens/startups/detalhes_screen.dart';
import 'package:mescla_invest/screens/carteira/carteira_screen.dart';

void main() async {
  /* Garante que o Flutter esteja pronto antes de inicializar o Firebase. */
  WidgetsFlutterBinding.ensureInitialized();

  /* Inicializa o Firebase usando as configurações da plataforma atual. */
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      darkTheme: AppTheme.temaPrincipal,
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginTela(),
        '/cadastro': (context) => const CadastroPage(),
        '/recuperacao_senha': (context) => const RecuperacaoSenhaTela(),

        /* Recebe dados do login para concluir a verificação em duas etapas. */
        '/verificacao_login': (context) {
          final args =
          ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;

          return VerificacaoLoginTela(
            email: args?['email']?.toString() ?? '',
            senha: args?['senha']?.toString() ?? '',
            setupRequired: args?['setupRequired'] == true ||
                args?['setupRequired']?.toString() == 'true',
            secret: args?['secret']?.toString(),
            otpAuthUri: args?['otpAuthUri']?.toString(),
          );
        },

        '/catalogo': (context) => const CatalogoStartupsPage(),
        '/detalhes': (context) => const DetalhesStartupPage(),
        '/balcao': (context) => const BalcaoDeNegociacoesScreen(),
        '/home': (context) => const CatalogoStartupsPage(),
        '/carteira': (context) => const CarteiraPage(),
        '/perfil': (context) => const PerfilPage(),
      },
    );
  }
}