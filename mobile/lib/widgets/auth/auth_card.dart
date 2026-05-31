/* Victória Nobre - 25016398 */
import 'package:flutter/material.dart';
import 'package:mescla_invest/themes/app_theme.dart';

/* Card base para os formulários de autenticação (Login, Cadastro, Recuperação) */
class AuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.bordaClara),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
