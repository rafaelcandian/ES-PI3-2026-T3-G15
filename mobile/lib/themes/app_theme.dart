import 'package:flutter/material.dart';

class AppColors {
  // ─── Fundos principais ───────────────────────────────────────────────────
  static const Color fundo = Color(0xFF070C30);
  static const Color fundoEscuro = Color(0xFF020818);

  // ─── Cards, campos e superfícies ─────────────────────────────────────────
  static const Color card = Color(0xFF0F1440);
  static const Color cardElevado = Color(0xFF16204A);
  static const Color campo = Color(0xFF1A2045);

  // ─── Cores institucionais ────────────────────────────────────────────────
  static const Color roxo = Color(0xFF403257);
  static const Color azul = Color(0xFF354377);

  // ─── Dourado / destaque ──────────────────────────────────────────────────
  static const Color destaque = Color(0xFFD4A72C);
  static const Color destaqueClaro = Color(0xFFE2B63D);
  static const Color destaqueEscuro = Color(0xFFAA7A13);

  // ─── Textos ──────────────────────────────────────────────────────────────
  static const Color branco = Colors.white;
  static const Color textoPrincipal = Colors.white;
  static const Color textoSecundario = Colors.white70;
  static const Color textoFraco = Color(0x80FFFFFF);
  static const Color textoMuitoFraco = Color(0x4DFFFFFF);

  // ─── Bordas e divisórias ─────────────────────────────────────────────────
  static const Color bordaClara = Color(0x12FFFFFF);
  static const Color bordaMedia = Color(0x1FFFFFFF);
  static const Color bordaDestaque = Color(0x33D4A72C);

  // ─── Estados ─────────────────────────────────────────────────────────────
  static const Color erro = Colors.red;
  static const Color sucesso = Color(0xFF4CAF50);
  static const Color alerta = Color(0xFFFFA726);
}

class AppLightColors {
  // ─── Fundos principais ───────────────────────────────────────────────────
  static const Color fundo = Color(0xFFF6F7FB);
  static const Color fundoEscuro = Color(0xFFE9ECF5);

  // ─── Cards, campos e superfícies ─────────────────────────────────────────
  static const Color card = Colors.white;
  static const Color cardElevado = Color(0xFFFFFBF2);
  static const Color campo = Color(0xFFF0F2FA);

  // ─── Cores institucionais ────────────────────────────────────────────────
  static const Color roxo = Color(0xFF403257);
  static const Color azul = Color(0xFF354377);

  // ─── Dourado / destaque ──────────────────────────────────────────────────
  static const Color destaque = Color(0xFFD4A72C);
  static const Color destaqueClaro = Color(0xFFE2B63D);
  static const Color destaqueEscuro = Color(0xFFAA7A13);

  // ─── Textos ──────────────────────────────────────────────────────────────
  static const Color textoPrincipal = Color(0xFF070C30);
  static const Color textoSecundario = Color(0xFF2D345A);
  static const Color textoFraco = Color(0xB3070C30);
  static const Color textoMuitoFraco = Color(0x73070C30);

  // ─── Bordas e divisórias ─────────────────────────────────────────────────
  static const Color bordaClara = Color(0x14070C30);
  static const Color bordaMedia = Color(0x26070C30);
  static const Color bordaDestaque = Color(0x44D4A72C);

  // ─── Estados ─────────────────────────────────────────────────────────────
  static const Color erro = Colors.red;
  static const Color sucesso = Color(0xFF4CAF50);
  static const Color alerta = Color(0xFFFFA726);
}

class AppTheme {
  static ThemeData temaPrincipal = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.fundo,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.azul,
      brightness: Brightness.dark,
      primary: AppColors.azul,
      secondary: AppColors.destaque,
      surface: AppColors.card,
      error: AppColors.erro,
    ),

    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppColors.destaque,
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
      titleMedium: TextStyle(
        color: AppColors.textoPrincipal,
        fontWeight: FontWeight.w600,
        fontSize: 24,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textoPrincipal,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textoSecundario,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: AppColors.textoMuitoFraco,
        fontSize: 12,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.destaque,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 50,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        shadowColor: Colors.black45,
        elevation: 5,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.campo,
      hintStyle: const TextStyle(
        color: AppColors.textoMuitoFraco,
        fontSize: 13,
      ),
      labelStyle: const TextStyle(
        color: AppColors.textoSecundario,
      ),
      prefixIconColor: AppColors.textoFraco,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.bordaClara,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.destaque,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.erro,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.erro,
          width: 1.4,
        ),
      ),
      errorStyle: const TextStyle(
        color: AppColors.erro,
        fontSize: 11,
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.fundo,
      foregroundColor: AppColors.textoPrincipal,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.destaque,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      iconTheme: IconThemeData(
        color: AppColors.textoPrincipal,
      ),
    ),
  );

  static ThemeData temaClaro = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppLightColors.fundo,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppLightColors.azul,
      brightness: Brightness.light,
      primary: AppLightColors.azul,
      secondary: AppLightColors.destaque,
      surface: AppLightColors.card,
      error: AppLightColors.erro,
    ),

    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppLightColors.destaque,
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
      titleMedium: TextStyle(
        color: AppLightColors.textoPrincipal,
        fontWeight: FontWeight.w600,
        fontSize: 24,
      ),
      bodyLarge: TextStyle(
        color: AppLightColors.textoPrincipal,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: AppLightColors.textoSecundario,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: AppLightColors.textoMuitoFraco,
        fontSize: 12,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppLightColors.destaque,
        foregroundColor: AppLightColors.textoPrincipal,
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 50,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        shadowColor: Colors.black26,
        elevation: 3,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppLightColors.campo,
      hintStyle: const TextStyle(
        color: AppLightColors.textoMuitoFraco,
        fontSize: 13,
      ),
      labelStyle: const TextStyle(
        color: AppLightColors.textoSecundario,
      ),
      prefixIconColor: AppLightColors.textoFraco,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppLightColors.bordaClara,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppLightColors.destaque,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppLightColors.erro,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppLightColors.erro,
          width: 1.4,
        ),
      ),
      errorStyle: const TextStyle(
        color: AppLightColors.erro,
        fontSize: 11,
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppLightColors.fundo,
      foregroundColor: AppLightColors.textoPrincipal,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppLightColors.destaque,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      iconTheme: IconThemeData(
        color: AppLightColors.textoPrincipal,
      ),
    ),
  );
}