import 'package:flutter/material.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:mescla_invest/screens/auth/splash_screen.dart';
import 'package:mescla_invest/screens/auth/login_screen.dart';
import 'package:mescla_invest/screens/auth/cadastro_screen.dart';
import 'package:mescla_invest/screens/auth/recuperacao_senha_screen.dart';
import 'package:mescla_invest/screens/startups/catalogo_screen.dart';
import 'package:mescla_invest/screens/startups/detalhes_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp();

  runApp(const MesclaInvestApp());
}

class MesclaInvestApp extends StatelessWidget {
  const MesclaInvestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mescla Invest',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070A1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3D64FF),
          secondary: Color(0xFFFFC53D),
          surface: Color(0xFF101730),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFB0B8D1)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF8B97B8)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: Colors.black87),
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
      initialRoute: "/",
      routes: {
        "/": (context) => const SplashScreen(),
        "/login": (context) => const LoginPage(),
        "/cadastro": (context) => const CadastroPage(),
        "/recuperacao_senha": (context) => const RecuperarSenhaPage(),
        "/catalogo": (context) => const CatalogoStartupsPage(),
        "/detalhes": (context) => const DetalhesStartupPage(),
      },
    );
  }
}

