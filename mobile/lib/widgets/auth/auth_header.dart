/* Victória Nobre - 25016398 */
import 'package:flutter/material.dart';
import 'package:mescla_invest/themes/app_theme.dart';

/* Cabeçalho padrão para telas de autenticação, contendo logo e títulos explicativos */
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset('assets/logo01.png', width: 160, fit: BoxFit.contain),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.destaque,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.45),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
