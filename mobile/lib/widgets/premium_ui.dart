import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

BoxDecoration premiumCardDecoration({
  double radius = 24,
  bool shadow = true,
}) {
  return BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: AppColors.bordaClara,
      width: 0.8,
    ),
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

BoxDecoration premiumFieldDecoration({
  double radius = 16,
}) {
  return BoxDecoration(
    color: AppColors.campo,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: AppColors.bordaClara,
      width: 0.8,
    ),
  );
}

class PremiumSectionLabel extends StatelessWidget {
  final String text;

  const PremiumSectionLabel({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.destaque,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.destaque,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class PremiumHeaderEyebrow extends StatelessWidget {
  final String text;

  const PremiumHeaderEyebrow({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.destaque,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.destaque,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}