import 'package:flutter/material.dart';
import 'package:mescla_invest/themes/app_theme.dart';

class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double height;
  final double radius;
  final IconData? icon;

  const OutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 52,
    this.radius = 16,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.destaque,
          side: const BorderSide(
            color: AppColors.bordaDestaque,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}