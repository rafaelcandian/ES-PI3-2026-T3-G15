import 'package:flutter/material.dart';
import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final EdgeInsetsGeometry padding;
  final double radius;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: premiumCardDecoration(radius: radius),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.destaque, size: 38),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textoPrincipal,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
