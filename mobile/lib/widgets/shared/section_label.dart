/* Victória Nobre - 25016398 */
import 'package:flutter/material.dart';
import 'package:mescla_invest/themes/app_theme.dart';

/* Rótulo de seção usado para separar blocos de conteúdo nas telas */
class SectionLabel extends StatelessWidget {
  final String label;
  final String? hint;
  final EdgeInsetsGeometry padding;

  const SectionLabel({
    super.key,
    required this.label,
    this.hint,
    this.padding = const EdgeInsets.symmetric(horizontal: 22),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textoMuitoFraco,
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              style: const TextStyle(
                color: AppColors.textoMuitoFraco,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
