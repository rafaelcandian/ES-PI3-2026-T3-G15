/* Victória Nobre - 25016398 */

import 'package:flutter/material.dart';
import 'package:mescla_invest/themes/app_theme.dart';

/* Cabeçalho reutilizável para telas internas do app. */
class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;

  final bool centered;
  final double titleFontSize;
  final double subtitleFontSize;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.centered = false,
    this.titleFontSize = 24,
    this.subtitleFontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final textAlign = centered ? TextAlign.center : TextAlign.left;
    final crossAxisAlignment =
    centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.bordaClara,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: icon == null
          ? Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Text(
            title,
            textAlign: textAlign,
            style: TextStyle(
              color: AppColors.destaque,
              fontSize: titleFontSize,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: textAlign,
            style: TextStyle(
              color: AppColors.textoFraco,
              fontSize: subtitleFontSize,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ],
      )
          : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.destaque.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.destaque.withValues(alpha: 0.28),
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.destaque,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: crossAxisAlignment,
              children: [
                Text(
                  title,
                  textAlign: textAlign,
                  style: TextStyle(
                    color: AppColors.destaque,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: textAlign,
                  style: TextStyle(
                    color: AppColors.textoFraco,
                    fontSize: subtitleFontSize,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}