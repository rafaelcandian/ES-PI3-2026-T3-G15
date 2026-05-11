import 'package:flutter/material.dart';
import 'package:mescla_invest/themes/app_theme.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final double height;
  final double radius;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.icon,
    this.height = 52,
    this.radius = 16,
    this.fontSize = 15,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return AnimatedOpacity(
      opacity: disabled ? 0.55 : 1,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: disabled
                  ? [
                Colors.white.withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.10),
              ]
                  : const [
                AppColors.destaqueClaro,
                AppColors.destaqueEscuro,
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: disabled
                ? []
                : [
              BoxShadow(
                color: AppColors.destaque.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: disabled || loading ? null : onTap,
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: Center(
                  child: loading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.fundo,
                    ),
                  )
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: AppColors.fundo,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: AppColors.fundo,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}