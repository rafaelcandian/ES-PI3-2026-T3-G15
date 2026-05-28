import 'package:flutter/material.dart';

class AuthSectionLabel extends StatelessWidget {
  final String label;

  const AuthSectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final destaque = Theme.of(context).colorScheme.secondary;

    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: destaque,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: destaque,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
