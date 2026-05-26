import 'package:flutter/material.dart';
import 'package:mescla_invest/themes/app_theme.dart';

class AppSnackBar {
  static void show(
      BuildContext context, {
        required String message,
        bool success = false,
        bool error = false,
        Duration duration = const Duration(seconds: 3),
      }) {
    ScaffoldMessenger.of(context).clearSnackBars();

    final IconData icon = success
        ? Icons.check_circle_outline_rounded
        : error
        ? Icons.error_outline_rounded
        : Icons.info_outline_rounded;

    final Color iconColor = success
        ? AppColors.destaque
        : error
            ? AppColors.erro
            : AppColors.textoFraco;

    final Color backgroundColor = error
        ? const Color(0xFF1A0A0A) // Vermelho muito escuro para erro
        : AppColors.card;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        elevation: 8,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: error
                ? AppColors.erro.withValues(alpha: 0.5)
                : iconColor.withValues(alpha: 0.3),
            width: error ? 1.5 : 0.8,
          ),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: error ? Colors.white : AppColors.textoPrincipal,
                  fontSize: 15,
                  height: 1.3,
                  fontWeight: error ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}