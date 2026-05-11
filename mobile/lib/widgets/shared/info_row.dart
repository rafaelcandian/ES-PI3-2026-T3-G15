import 'package:flutter/material.dart';
import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool destaque;
  final bool boxed;
  final EdgeInsetsGeometry padding;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.destaque = false,
    this.boxed = false,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: destaque ? AppColors.textoPrincipal : AppColors.textoFraco,
              fontSize: destaque ? 14 : 13,
              fontWeight: destaque ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: destaque ? AppColors.destaque : AppColors.textoPrincipal,
              fontSize: destaque ? 16 : 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );

    if (!boxed) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: content,
      );
    }

    return Container(
      padding: padding,
      decoration: premiumFieldDecoration(
        radius: 16,
      ),
      child: content,
    );
  }
}