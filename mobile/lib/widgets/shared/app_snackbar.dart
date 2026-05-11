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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: iconColor.withValues(alpha: 0.35),
            width: 0.7,
          ),
        ),
        content: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.textoPrincipal,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}