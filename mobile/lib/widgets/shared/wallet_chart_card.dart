/* Victória Nobre - 25016398 */
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';

/* Componente de Visualização Analítica (Dashboard). 
   Abstrai o motor de renderização gráfica e gerencia a normalização de escalas financeiras 
   para exibir a curva de patrimônio líquido (Net Worth) ao longo do tempo. */
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

  static const List<String> _periods = [
    '1h',
    '24h',
    '1 sem',
    '1 mês',
    '6 meses',
    '1 ano',
  ];

  double _safeDouble(double value, [double fallback = 0.0]) {
    return value.isFinite ? value : fallback;
  }

  /* Realiza o 'Clamping' e a normalização dos dados. 
     Garante que valores infinitos ou nulos (NaN) provenientes de erros de divisão por zero 
     no cálculo de variação não quebrem o pipeline de renderização (Canvas). */
  List<double> _safeChartData() {
    final cleaned = data.where((value) => value.isFinite).toList();

    if (cleaned.isEmpty) {
      final safeStart = _safeDouble(startValue);
      final safeEnd = _safeDouble(endValue, safeStart);

      return [safeStart, safeEnd];
    }

    if (cleaned.length == 1) {
      return [cleaned.first, cleaned.first];
    }

    return cleaned;
  }

  String _formatMoney(double value) {
    final safeValue = _safeDouble(value);
    return 'R\$ ${safeValue.toStringAsFixed(2)}';
  }

  String _middleLabel() {
    if (points.length < 3) return '';
    return (points[points.length ~/ 2]['label'] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _safeChartData();

    final safeStartValue = _safeDouble(
      startValue,
      chartData.isNotEmpty ? chartData.first : 0.0,
    );

    final safeEndValue = _safeDouble(
      endValue,
      chartData.isNotEmpty ? chartData.last : safeStartValue,
    );

    final calculatedVariation = safeEndValue - safeStartValue;

    final safeVariation = variation.isFinite ? variation : calculatedVariation;

    final calculatedPercent = safeStartValue.abs() > 0
        ? (calculatedVariation / safeStartValue.abs()) * 100
        : 0.0;

    final safeVariationPercent = variationPercent.isFinite
        ? variationPercent
        : calculatedPercent;

    final positivo = safeVariation >= 0;
    final middleLabel = _middleLabel();

    final startText = startLabel.trim().isEmpty ? 'Início' : startLabel;
    final endText = endLabel.trim().isEmpty ? 'Atual' : endLabel;

    final variacaoTexto =
        '${positivo ? '+' : '-'} ${_formatMoney(safeVariation.abs())} '
        '(${positivo ? '+' : '-'}${safeVariationPercent.abs().toStringAsFixed(1)}%)';

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
                  child: PremiumHeaderEyebrow(text: 'EVOLUÇÃO DO PATRIMÔNIO'),
                ),
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
            Row(
              children: [
                Expanded(
                  child: _ChartMetricBox(
                    label: 'Início',
                    value: _formatMoney(safeStartValue),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ChartMetricBox(
                    label: 'Atual',
                    value: _formatMoney(safeEndValue),
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
                    color: positivo ? AppColors.destaque : Colors.white70,
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
                  Flexible(
                    child: Text(
                      variacaoTexto,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: positivo ? AppColors.destaque : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _LineChartPainter(data: chartData),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    startText,
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
                    endText,
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
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _periods.map((period) {
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
                            color: active ? AppColors.destaque : AppColors.campo,
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

/* Motor de Renderização de Baixo Nível (Canvas Engine).
   Utiliza a API de CustomPainter do Flutter para desenhar a curva de patrimônio. 
   O algoritmo converte coordenadas financeiras (Valor x Tempo) em coordenadas de pixel (X x Y)
   usando interpolação linear e suavização por Curvas de Bézier Cúbicas. */
class _LineChartPainter extends CustomPainter {
  final List<double> data;

  _LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final values = data.where((value) => value.isFinite).toList();

    if (values.length < 2 || size.width <= 0 || size.height <= 0) return;

    /* Desenha linhas de grade horizontais para referência visual de profundidade */
    final gridPaint = Paint()
      ..color = AppColors.bordaClara
      ..strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    /* Cálculo de Normalização de Escala (Min-Max Scaling).
       Mapeia o domínio dos dados [min, max] para o intervalo de pixels da tela.
       Se a variação for desprezível (Flat Line), aplica um 'padding' artificial para evitar
       artefatos visuais de linhas colapsadas. */
    var minValue = values.reduce(math.min);
    var maxValue = values.reduce(math.max);

    if (!minValue.isFinite || !maxValue.isFinite) return;

    final rawRange = maxValue - minValue;
    final isFlat = rawRange.abs() < 0.01;

    if (isFlat) {
      final adjustment = minValue.abs() > 0 ? minValue.abs() * 0.05 : 1.0;
      minValue -= adjustment;
      maxValue += adjustment;
    }

    final range = maxValue - minValue;

    if (range <= 0 || !range.isFinite) return;

    final points = <Offset>[];
    final horizontalPadding = 8.0;
    final topPadding = 16.0;
    final bottomPadding = 18.0;

    final usableWidth = size.width - (horizontalPadding * 2);
    final usableHeight = size.height - topPadding - bottomPadding;
    final space = usableWidth / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final normalized = (values[i] - minValue) / range;

      final x = horizontalPadding + (i * space);
      final y = topPadding + usableHeight - (normalized * usableHeight);

      if (x.isFinite && y.isFinite) {
        points.add(Offset(x, y));
      }
    }

    if (points.length < 2) return;

    /* Interpolação de Splines (Bezier Smoothing).
       Em vez de linhas retas (polilinhas), utiliza path.cubicTo para gerar uma curva 
       suave, calculando pontos de controle (CP1, CP2) que garantem continuidade visual 
       mesmo com poucos pontos de dados. */
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
      ..lineTo(points.last.dx, size.height - bottomPadding)
      ..lineTo(points.first.dx, size.height - bottomPadding)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.destaque.withValues(alpha: 0.20),
          AppColors.destaque.withValues(alpha: 0.00),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.destaqueClaro, AppColors.destaqueEscuro],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()
      ..color = AppColors.destaque
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = AppColors.card
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final lastPoint = points.last;

    canvas.drawCircle(lastPoint, 5, dotPaint);
    canvas.drawCircle(lastPoint, 5, dotBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}