/* Victória Nobre - 25016398 */
import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

/* Utilitários de UI para garantir a estética Premium consistente em todo o aplicativo */

/* Decoração padrão para cards com gradientes e sombras suaves */
BoxDecoration premiumCardDecoration({double radius = 24, bool shadow = true}) {
  return BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.bordaClara, width: 0.8),
    boxShadow: shadow
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.32),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ]
        : [],
  );
}

BoxDecoration premiumFieldDecoration({double radius = 16}) {
  return BoxDecoration(
    color: AppColors.campo,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.bordaClara, width: 0.8),
  );
}

class PremiumSectionLabel extends StatelessWidget {
  final String text;

  const PremiumSectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.white.withOpacity(0.72),
        letterSpacing: 1.1,
      ),
    );
  }
}

class PremiumHeaderEyebrow extends StatelessWidget {
  final String text;

  const PremiumHeaderEyebrow({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        color: Colors.white.withOpacity(0.65),
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
