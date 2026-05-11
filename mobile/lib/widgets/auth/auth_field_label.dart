import 'package:flutter/material.dart';
import 'package:mescla_invest/themes/app_theme.dart';

class AuthFieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const AuthFieldLabel({
    super.key,
    required this.label,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final destaque = Theme.of(context).colorScheme.secondary;

    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textoFraco,
            letterSpacing: 0.3,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: destaque,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}