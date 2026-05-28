import 'package:flutter/material.dart';
import 'package:mescla_invest/themes/app_theme.dart';

class AtmosphericBackground extends StatelessWidget {
  final double topGlowOpacity;
  final double middleGlowOpacity;
  final double bottomGlowOpacity;

  const AtmosphericBackground({
    super.key,
    this.topGlowOpacity = 0.22,
    this.middleGlowOpacity = 0.07,
    this.bottomGlowOpacity = 0.18,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -150,
              right: -120,
              child: _GlowCircle(
                size: 340,
                color: AppColors.azul,
                opacity: topGlowOpacity,
              ),
            ),
            Positioned(
              top: 230,
              left: -130,
              child: _GlowCircle(
                size: 280,
                color: AppColors.destaque,
                opacity: middleGlowOpacity,
              ),
            ),
            Positioned(
              bottom: 70,
              right: -120,
              child: _GlowCircle(
                size: 300,
                color: AppColors.roxo,
                opacity: bottomGlowOpacity,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowCircle({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
