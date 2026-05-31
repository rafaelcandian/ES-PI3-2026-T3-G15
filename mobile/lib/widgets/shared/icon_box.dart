/* Victória Nobre - 25016398 */
import 'package:flutter/material.dart';
import 'package:mescla_invest/themes/app_theme.dart';

/* Container estilizado para ícones seguindo o design system do projeto */
class IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final double radius;
  final BoxShape shape;

  const IconBox({
    super.key,
    required this.icon,
    this.color = AppColors.destaque,
    this.size = 42,
    this.iconSize = 20,
    this.radius = 14,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
