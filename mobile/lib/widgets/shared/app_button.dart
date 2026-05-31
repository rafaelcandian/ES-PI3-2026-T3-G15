/* Victória Nobre - 25016398 */
import 'package:flutter/material.dart';

import 'package:mescla_invest/themes/app_theme.dart';

/* Variantes de botão para manter consistência visual em todo o app */
enum AppButtonVariant {
  primary,
  outline,
}

/* Botão customizado com suporte a estados de carregamento e variações de estilo */
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading; /* Estado de carregamento para feedback visual durante chamadas Firebase/Functions */
  final IconData? icon;
  final AppButtonVariant variant;
  final bool fullWidth;

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.icon,
    this.fullWidth = true,
  }) : variant = AppButtonVariant.primary;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.icon,
    this.fullWidth = true,
  }) : variant = AppButtonVariant.outline;

  static const double _primaryHeight = 52;
  static const double _outlineHeight = 48;

  static const double _primaryRadius = 18;
  static const double _outlineRadius = 16;

  static const double _fontSize = 14.5;
  static const double _iconSize = 18;

  bool get _isPrimary => variant == AppButtonVariant.primary;

  double get _height => _isPrimary ? _primaryHeight : _outlineHeight;

  double get _radius => _isPrimary ? _primaryRadius : _outlineRadius;

  @override
  Widget build(BuildContext context) {
    /* Bloqueia interação se estiver em modo de carregamento ou desabilitado */
    final disabled = onTap == null;
    final foregroundColor = _isPrimary ? AppColors.fundo : AppColors.destaque;

    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: disabled
          ? foregroundColor.withValues(alpha: 0.58)
          : foregroundColor,
      fontSize: _fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.1,
    ) ??
        TextStyle(
          color: disabled
              ? foregroundColor.withValues(alpha: 0.58)
              : foregroundColor,
          fontSize: _fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.1,
        );

    return AnimatedOpacity(
      opacity: disabled ? 0.55 : 1,
      duration: const Duration(milliseconds: 180),
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        height: _height,
        child: DecoratedBox(
          decoration: _decoration(disabled),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(_radius),
            child: InkWell(
              borderRadius: BorderRadius.circular(_radius),
              onTap: disabled || loading ? null : onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Center(
                  /* Exibe indicador de progresso se o estado for 'loading' */
                  child: loading
                      ? SizedBox(
                    width: _isPrimary ? 21 : 19,
                    height: _isPrimary ? 21 : 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: foregroundColor,
                    ),
                  )
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: disabled
                              ? foregroundColor.withValues(alpha: 0.58)
                              : foregroundColor,
                          size: _iconSize,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: textStyle,
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

  BoxDecoration _decoration(bool disabled) {
    if (_isPrimary) {
      return BoxDecoration(
        color: disabled
            ? Colors.white.withValues(alpha: 0.12)
            : AppColors.destaque,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: disabled
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.destaqueClaro.withValues(alpha: 0.24),
          width: 1,
        ),
        boxShadow: disabled
            ? []
            : [
          BoxShadow(
            color: AppColors.destaque.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }

    return BoxDecoration(
      color: Colors.white.withValues(alpha: disabled ? 0.02 : 0.035),
      borderRadius: BorderRadius.circular(_radius),
      border: Border.all(
        color: disabled
            ? Colors.white.withValues(alpha: 0.10)
            : AppColors.destaque.withValues(alpha: 0.36),
        width: 1,
      ),
      boxShadow: const [],
    );
  }
}