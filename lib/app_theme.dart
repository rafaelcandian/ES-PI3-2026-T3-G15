import 'package:flutter/material.dart';

class AppColors {
  static const Color fundo = Color(0xFF090F32);
  static const Color roxo = Color(0xFF3D2B61);
  static const Color azul = Color(0xFF424F81);
  static const Color destaque = Color(0xFFEFC855);
  static const Color branco = Colors.white;
  static const Color erro = Colors.red;
}

class AppTheme {
  static ThemeData temaPrincipal = ThemeData(
    scaffoldBackgroundColor: AppColors.fundo,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.azul,
      primary: AppColors.azul,
      secondary: AppColors.roxo,
      error: AppColors.erro,
    ),

    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppColors.destaque,
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(
        color: AppColors.branco,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.destaque,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.branco,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}