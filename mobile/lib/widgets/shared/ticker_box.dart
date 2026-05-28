import 'package:flutter/material.dart';
import 'package:mescla_invest/themes/app_theme.dart';

class TickerBox extends StatelessWidget {
  final String simbolo;
  final Color color;
  final double size;

  const TickerBox({
    super.key,
    required this.simbolo,
    this.color = AppColors.destaque,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.30),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Center(
        child: Text(
          simbolo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: size > 50 ? 14 : 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
