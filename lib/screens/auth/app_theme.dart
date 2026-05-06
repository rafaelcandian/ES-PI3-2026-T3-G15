import 'package:flutter/material.dart';

class AppColors {
  static const Color fundo = Color(0xFF070C30); // Cor de fundo escura
  static const Color roxo = Color(0xFF403257); // Cor secundária
  static const Color azul = Color(0xFF354377); // Cor de destaque
  static const Color destaque = Color(0xFFB88E13); // Cor amarela de destaque
  static const Color branco = Colors.white; // Cor branca
  static const Color erro = Colors.red; // Cor de erro
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
        fontSize: 32, // Aumenta o tamanho do título
      ),
      bodyMedium: TextStyle(
        color: AppColors.branco,
        fontSize: 16, // Ajuste o tamanho do texto para melhor legibilidade
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.destaque,
        foregroundColor: AppColors.branco,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Arredondamento maior
        ),
        shadowColor: Colors.black.withOpacity(0.3), // Sombra suave
        elevation: 5, // Elevação maior para dar destaque
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C3541), // Cor de fundo mais escura para os campos
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15), // Bordas mais arredondadas
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Colors.white70), // Estilo de texto das dicas
      labelStyle: const TextStyle(
        color: Colors.white, // Cor do rótulo dentro do campo
      ),
      prefixIconColor: Colors.white, // Cor dos ícones nos campos de entrada
    ),

    // Ajuste na barra de status, caso deseje personalizar (não é obrigatório)
    appBarTheme: const AppBarTheme(
      color: AppColors.fundo, // Cor de fundo da AppBar
      titleTextStyle: TextStyle(
        color: AppColors.destaque, // Cor do título da AppBar
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      elevation: 0, // Remover sombra da AppBar
    ),
  );
}