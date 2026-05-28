import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';

class WalletChartCard extends StatelessWidget {
  final List<double> data;
  final List<Map<String, dynamic>> points;
  final String selectedTimePeriod;
  final double startValue;
  final double endValue;
  final double variation;
  final double variationPercent;
  final String startLabel;
  final String endLabel;
  final ValueChanged<String> onPeriodChanged;
  final double horizontalPadding;

  const WalletChartCard({
    super.key,
    required this.data,
    this.points = const [],
    required this.selectedTimePeriod,
    this.startValue = 0.0,
    this.endValue = 0.0,
    this.variation = 0.0,
    this.variationPercent = 0.0,
    this.startLabel = '',
    this.endLabel = '',
    required this.onPeriodChanged,
    this.horizontalPadding = 22,
  });

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2)}';
  }

  String _middleLabel() {
    if (points.length < 3) return '';
    return (points[points.length ~/ 2]['label'] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    final periods = ['1h', '24h', '1 sem', '1 mês', '6 meses', '1 ano'];
    final temHistorico = data.length >= 2;
    final positivo = variation >= 0;
    final middleLabel = _middleLabel();

    final variacaoTexto =
        '${positivo ? '+' : '-'} ${_formatMoney(variation.abs())} '
        '(${positivo ? '+' : '-'}${variationPercent.abs().toStringAsFixed(1)}%)';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: premiumCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: PremiumHeaderEyebrow(
                    text: 'EVOLUÇÃO DO PATRIMÔNIO',
                  ),
                ),
                if (temHistorico)
                  Text(
                    selectedTimePeriod,
                    style: const TextStyle(
                      color: AppColors.destaque,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (temHistorico) ...[
              Row(
                children: [
                  Expanded(
                    child: _ChartMetricBox(
                      label: 'Início',
                      value: _formatMoney(startValue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ChartMetricBox(
                      label: 'Atual',
                      value: _formatMoney(endValue),
                      destaque: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: premiumFieldDecoration(radius: 14),
                child: Row(
                  children: [
                    Icon(
                      positivo
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color:
                      positivo ? AppColors.destaque : const Color(0xFFF87171),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Variação no período',
                        style: TextStyle(
                          color: AppColors.textoMuitoFraco,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      variacaoTexto,
                      style: TextStyle(
                        color: positivo
                            ? AppColors.destaque
                            : const Color(0xFFF87171),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 180,
              width: double.infinity,
              child: temHistorico
                  ? CustomPaint(
                painter: _LineChartPainter(data: data),
              )
                  : Center(
                child: Text(
                  'Ainda não há pontos suficientes para este período. '
                      'Faça um aporte, compra ou venda para gerar histórico.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textoMuitoFraco.withOpacity(0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (temHistorico) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      startLabel,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: AppColors.textoMuitoFraco,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (middleLabel.isNotEmpty)
                    Expanded(
                      child: Text(
                        middleLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textoMuitoFraco,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      endLabel,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.textoMuitoFraco,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: periods.map((period) {
                  final active = selectedTimePeriod == period;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => onPeriodChanged(period),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color:
                            active ? AppColors.destaque : AppColors.campo,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: active
                                  ? AppColors.destaque
                                  : AppColors.bordaClara,
                            ),
                          ),
                          child: Text(
                            period,
                            style: TextStyle(
                              color: active
                                  ? AppColors.fundo
                                  : AppColors.textoFraco,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final bool destaque;

  const _ChartMetricBox({
    required this.label,
    required this.value,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: premiumFieldDecoration(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: destaque ? AppColors.destaque : AppColors.textoPrincipal,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;

  _LineChartPainter({
    required this.data,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final gridPaint = Paint()
      ..color = AppColors.bordaClara
      ..strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final minValue = data.reduce(math.min);
    final maxValue = data.reduce(math.max);
    final rawRange = maxValue - minValue;
    final isFlat = rawRange.abs() < 0.01;
    final range = isFlat ? 1.0 : rawRange;

    final points = <Offset>[];
    final horizontalPadding = 8.0;
    final usableWidth = size.width - (horizontalPadding * 2);
    final space = usableWidth / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final normalized = isFlat ? 0.5 : (data[i] - minValue) / range;
      final x = horizontalPadding + (i * space);
      final y = size.height - (normalized * size.height * 0.72) - 22;

      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlPointX = (previous.dx + current.dx) / 2;

      path.cubicTo(
        controlPointX,
        previous.dy,
        controlPointX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.destaque.withOpacity(0.20),
          AppColors.destaque.withOpacity(0.00),
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          AppColors.destaqueClaro,
          AppColors.destaqueEscuro,
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()
      ..color = AppColors.destaque
      ..style = PaintingStyle.fill;

    final lastPoint = points.last;
    canvas.drawCircle(lastPoint, 5, dotPaint);

    final dotBorderPaint = Paint()
      ..color = AppColors.card
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(lastPoint, 5, dotBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}