import 'package:flutter/material.dart';
import 'package:mescla_invest/themes/app_theme.dart';

class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      '© 2026 MESCLA INVEST  •  ACADEMIC & FINANCIAL EXCELLENCE',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 9,
        color: AppColors.textoMuitoFraco,
        letterSpacing: 1.4,
        height: 1.8,
      ),
    );
  }
}