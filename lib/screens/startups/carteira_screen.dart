import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mescla_invest/widgets/bottom_nav_bar.dart';

class CarteiraPage extends StatefulWidget {
  const CarteiraPage({super.key});

  @override
  State<CarteiraPage> createState() => _CarteiraPageState();
}

class _CarteiraPageState extends State<CarteiraPage> {
  String selectedTimePeriod = '1 mês';

  final List<double> data = [0.22, 0.34, 0.28, 0.52, 0.47, 0.72, 0.66, 0.88];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _TopBar(),
                  const SizedBox(height: 28),

                  const _Header(),
                  const SizedBox(height: 22),

                  const _PatrimonioCard(),
                  const SizedBox(height: 18),

                  _GraficoCard(
                    data: data,
                    selectedTimePeriod: selectedTimePeriod,
                    onPeriodChanged: (period) {
                      setState(() => selectedTimePeriod = period);
                    },
                  ),

                  const SizedBox(height: 22),

                  const _SectionTitle('Seus ativos'),
                  const SizedBox(height: 12),

                  const _AtivoCard(
                    nome: 'NeuroPulse AI',
                    simbolo: 'NPA',
                    tokens: 120,
                    valorToken: 'R\$ 25,50',
                    variacao: '+3.2%',
                  ),
                  const SizedBox(height: 10),
                  const _AtivoCard(
                    nome: 'BioSync',
                    simbolo: 'BIO',
                    tokens: 80,
                    valorToken: 'R\$ 29,50',
                    variacao: '+7.3%',
                  ),
                  const SizedBox(height: 10),
                  const _AtivoCard(
                    nome: 'QuantLedger',
                    simbolo: 'QLG',
                    tokens: 45,
                    valorToken: 'R\$ 24,50',
                    variacao: '-1.4%',
                  ),

                  const SizedBox(height: 22),

                  const _SectionTitle('Últimas movimentações'),
                  const SizedBox(height: 12),

                  const _MovimentacaoTile(
                    titulo: 'Compra executada',
                    descricao: '100 tokens NPA',
                    valor: '- R\$ 2.500,00',
                  ),
                  const _MovimentacaoTile(
                    titulo: 'Venda executada',
                    descricao: '50 tokens QLG',
                    valor: '+ R\$ 1.250,00',
                  ),
                ],
              ),
            ),
          ),

          const BottomNavBar(selectedIndex: 2),
        ],
      ),
    );
  }
}

class _C {
  static const bg           = Color(0xFF020818);
  static const surface      = Color(0xFF0B1230);
  static const surfaceRaised = Color(0xFF0F1840);
  static const card         = Color(0xFF0D1535);
  static const gold         = Color(0xFFEFCD57);
  static const goldDim      = Color(0xFFB89A2E);
  static const goldGlow     = Color(0x22EFCD57);
  static const goldBorder   = Color(0x33EFCD57);
  static const white        = Colors.white;
  static const white70      = Colors.white70;
  static const white50      = Color(0x80FFFFFF);
  static const white30      = Color(0x4DFFFFFF);
  static const white12      = Color(0x1FFFFFFF);
  static const white06      = Color(0x0FFFFFFF);
  static const blue         = Color(0xFF1A3A8F);
}
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _C.gold, width: 1),
          ),
          child: const Icon(Icons.account_balance_wallet_rounded, color: _C.gold, size: 18),
        ),
        const Spacer(),
        const Text(
          'MESCLAINVEST',
          style: TextStyle(
            fontFamily: 'Syne',
            color: _C.gold,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.6,
          ),
        ),
        const Spacer(),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.white12),
          ),
          child: const Icon(Icons.notifications_outlined, color: _C.gold, size: 20),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Carteira',
          style: TextStyle(
            fontFamily: 'Syne',
            color: _C.white,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Resumo dos seus ativos digitais simulados.',
          style: TextStyle(
            color: _C.white50,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _PatrimonioCard extends StatelessWidget {
  const _PatrimonioCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _C.white12, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: _C.gold.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PATRIMÔNIO TOTAL',
            style: TextStyle(
              color: _C.white50,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'R\$ 1.125.000,00',
            style: TextStyle(
              fontFamily: 'Syne',
              color: _C.gold,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              Expanded(
                child: _ResumoItem(label: 'Saldo disponível', value: 'R\$ 12.750,00'),
              ),
              Expanded(
                child: _ResumoItem(label: 'Tokens totais', value: '4.500'),
              ),
              Expanded(
                child: _ResumoItem(label: 'Variação', value: '+3.2%'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  final String label;
  final String value;

  const _ResumoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _C.white30, fontSize: 10)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: _C.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _GraficoCard extends StatelessWidget {
  final List<double> data;
  final String selectedTimePeriod;
  final ValueChanged<String> onPeriodChanged;

  const _GraficoCard({
    required this.data,
    required this.selectedTimePeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final periods = ['1h', '24h', '1 sem', '1 mês', '6 meses', '1 ano'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.white12, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Valorização da carteira',
            style: TextStyle(
              color: _C.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            width: double.infinity,
            child: CustomPaint(
              painter: LineChartPainter(data: data),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: periods.map((period) {
                final active = selectedTimePeriod == period;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onPeriodChanged(period),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: active ? _C.gold : _C.white06,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        period,
                        style: TextStyle(
                          color: active ? _C.surface : _C.white50,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
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
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: _C.white30,
        fontSize: 10,
        letterSpacing: 2,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _AtivoCard extends StatelessWidget {
  final String nome;
  final String simbolo;
  final int tokens;
  final String valorToken;
  final String variacao;

  const _AtivoCard({
    required this.nome,
    required this.simbolo,
    required this.tokens,
    required this.valorToken,
    required this.variacao,
  });

  @override
  Widget build(BuildContext context) {
    final negative = variacao.startsWith('-');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.white06, width: 0.7),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _C.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.gold.withOpacity(0.35)),
            ),
            child: Center(
              child: Text(
                simbolo,
                style: const TextStyle(
                  color: _C.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    color: _C.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$tokens tokens • $valorToken/token',
                  style: const TextStyle(color: _C.white30, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            variacao,
            style: TextStyle(
              color: negative ? _C.white50 : _C.gold,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovimentacaoTile extends StatelessWidget {
  final String titulo;
  final String descricao;
  final String valor;

  const _MovimentacaoTile({
    required this.titulo,
    required this.descricao,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final entrada = valor.startsWith('+');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.white06),
      ),
      child: Row(
        children: [
          Icon(
            entrada ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: _C.gold,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: _C.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  descricao,
                  style: const TextStyle(color: _C.white30, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              color: _C.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> data;

  LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _C.white06
      ..strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [_C.gold, _C.goldDim],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final space = size.width / (data.length - 1);
    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * space;
      final y = size.height - (data[i] * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}