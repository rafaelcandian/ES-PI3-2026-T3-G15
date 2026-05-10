import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mescla_invest/widgets/bottom_nav_bar.dart';
import 'package:mescla_invest/widgets/app_bar_padrao.dart';
import 'package:mescla_invest/services/carteira_service.dart';
import 'package:mescla_invest/services/startup_service.dart';

import '../../models/balcao_model.dart';
import '../auth/app_theme.dart';
import '../ordens/ordem_exe_screen.dart';

class CarteiraPage extends StatefulWidget {
  const CarteiraPage({super.key});

  @override
  State<CarteiraPage> createState() => _CarteiraPageState();
}

class _CarteiraPageState extends State<CarteiraPage> {
  String selectedTimePeriod = '1 mês';

  final List<double> data = [
    0.28,
    0.34,
    0.31,
    0.48,
    0.44,
    0.62,
    0.58,
    0.76,
    0.71,
    0.88,
  ];

  double _saldo = 0.0;
  List<AtivoCarteira> _ativos = [];
  List<Map<String, dynamic>> _movimentacoes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final carteiraService = CarteiraService();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      
      if (uid == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final saldo = await carteiraService.getBalance();
      final tokensMap = await carteiraService.getTokens();

      List<AtivoCarteira> ativosTemp = [];
      final firestore = FirebaseFirestore.instance;

      for (var entry in tokensMap.entries) {
        final startupId = entry.key;
        final quantidade = entry.value;

        if (quantidade > 0) {
          final doc = await firestore.collection('startups').doc(startupId).get();
          if (doc.exists) {
            final data = doc.data()!;
            final title = data['title'] ?? 'Startup';
            final tokenValue = (data['tokenValue'] ?? 0.0).toDouble();

            ativosTemp.add(AtivoCarteira(
              nome: title,
              simbolo: title.length >= 3 ? title.substring(0, 3).toUpperCase() : title.toUpperCase(),
              tokens: (quantidade as num).toInt(),
              valorToken: tokenValue,
              precoMedio: tokenValue,
              variacao: 0.0,
              volume: '0',
              spread: 0.0,
            ));
          }
        }
      }

      final compras = await firestore
          .collection('transactions')
          .where('buyerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final vendas = await firestore
          .collection('transactions')
          .where('sellerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final todasMovs = [...compras.docs, ...vendas.docs];
      todasMovs.sort((a, b) => 
        (b.data()['createdAt'] as Timestamp)
        .compareTo(a.data()['createdAt'] as Timestamp));

      List<Map<String, dynamic>> movsTemp = todasMovs
          .take(5)
          .map((doc) => doc.data())
          .toList();

      if (mounted) {
        setState(() {
          _saldo = saldo;
          _ativos = ativosTemp;
          _movimentacoes = movsTemp;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  double get patrimonioTotal {
    return _ativos.fold<double>(
      0,
          (total, ativo) => total + ativo.valorTotal,
    );
  }

  int get tokensTotais {
    return _ativos.fold<int>(
      0,
          (total, ativo) => total + ativo.tokens,
    );
  }

  double get variacaoMedia {
    if (_ativos.isEmpty) return 0;

    final soma = _ativos.fold<double>(
      0,
          (total, ativo) => total + ativo.variacao,
    );

    return soma / _ativos.length;
  }

  double get saldoDisponivel => _saldo;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.fundoEscuro,
        extendBody: true,
        appBar: const AppBarPadrao(titulo: 'Minha Carteira'),
        bottomNavigationBar: const BottomNavBar(selectedIndex: 2),
        body: Stack(
          children: [
            const _AtmosphericBackground(),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.destaque),
              )
            else
              SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _Header(),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: _PatrimonioCard(
                      patrimonioTotal: patrimonioTotal,
                      saldoDisponivel: saldoDisponivel,
                      tokensTotais: tokensTotais,
                      variacaoMedia: variacaoMedia,
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 18),
                  ),

                  SliverToBoxAdapter(
                    child: _GraficoCard(
                      data: data,
                      selectedTimePeriod: selectedTimePeriod,
                      onPeriodChanged: (period) {
                        setState(() => selectedTimePeriod = period);
                      },
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 22),
                  ),

                  const SliverToBoxAdapter(
                    child: _SectionLabel(
                      label: 'SEUS ATIVOS',
                      hint: 'Acompanhe seus tokens e a valorização por startup.',
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 12),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    sliver: SliverList.separated(
                      itemCount: _ativos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ativo = _ativos[index];

                        return _AtivoCard(
                          ativo: ativo,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AtivoDetalheScreen(
                                  ativo: ativo,
                                  historico: data,
                                  ofertasDisponiveis: _ofertasDoAtivo(ativo),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),

                  const SliverToBoxAdapter(
                    child: _SectionLabel(
                      label: 'ÚLTIMAS MOVIMENTAÇÕES',
                      hint: 'Histórico recente das operações simuladas.',
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 12),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    sliver: _movimentacoes.isEmpty 
                      ? const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'Nenhuma movimentação recente.',
                                style: TextStyle(color: AppColors.textoFraco),
                              ),
                            ),
                          ),
                        )
                      : SliverList.separated(
                          itemCount: _movimentacoes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final mov = _movimentacoes[index];
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            final isBuy = mov['buyerId'] == uid;
                            final quantity = mov['quantity'] ?? 0;
                            final totalPrice = mov['totalPrice']?.toDouble() ?? 0.0;
                            
                            return _MovimentacaoTile(
                              titulo: isBuy ? 'Compra executada' : 'Venda executada',
                              descricao: '$quantity tokens',
                              valor: '${isBuy ? '-' : '+'} R\$ ${totalPrice.toStringAsFixed(2)}',
                            );
                          },
                        ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Oferta> _ofertasDoAtivo(AtivoCarteira ativo) {
    return [
      Oferta(
        tipo: TipoOferta.venda,
        quantidade: ativo.tokens,
        preco: ativo.valorToken,
        empresa: ativo.nome,
        simbolo: ativo.simbolo,
        variacao: ativo.variacao,
        volume: ativo.volume,
        spread: ativo.spread,
      ),
      Oferta(
        tipo: TipoOferta.venda,
        quantidade: math.max(1, (ativo.tokens * 0.65).round()),
        preco: ativo.valorToken + 0.80,
        empresa: ativo.nome,
        simbolo: ativo.simbolo,
        variacao: ativo.variacao,
        volume: ativo.volume,
        spread: ativo.spread + 0.3,
      ),
      Oferta(
        tipo: TipoOferta.compra,
        quantidade: math.max(1, (ativo.tokens * 0.45).round()),
        preco: ativo.valorToken - 0.60,
        empresa: ativo.nome,
        simbolo: ativo.simbolo,
        variacao: ativo.variacao,
        volume: ativo.volume,
        spread: ativo.spread + 0.2,
      ),
    ];
  }
}

// ─── Modelo interno da carteira ─────────────────────────────────────────────

class AtivoCarteira {
  final String nome;
  final String simbolo;
  final int tokens;
  final double valorToken;
  final double precoMedio;
  final double variacao;
  final String volume;
  final double spread;

  const AtivoCarteira({
    required this.nome,
    required this.simbolo,
    required this.tokens,
    required this.valorToken,
    required this.precoMedio,
    required this.variacao,
    required this.volume,
    required this.spread,
  });

  double get valorTotal => tokens * valorToken;

  double get lucroPrejuizo => (valorToken - precoMedio) * tokens;
}

// ─── Tela de detalhe do ativo ───────────────────────────────────────────────

class AtivoDetalheScreen extends StatefulWidget {
  final AtivoCarteira ativo;
  final List<double> historico;
  final List<Oferta> ofertasDisponiveis;

  const AtivoDetalheScreen({
    super.key,
    required this.ativo,
    required this.historico,
    required this.ofertasDisponiveis,
  });

  @override
  State<AtivoDetalheScreen> createState() => _AtivoDetalheScreenState();
}

class _AtivoDetalheScreenState extends State<AtivoDetalheScreen> {
  String selectedTimePeriod = '1 mês';

  bool get _positivo => widget.ativo.variacao >= 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundoEscuro,
      body: Stack(
        children: [
          const _AtmosphericBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textoPrincipal,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Detalhe do ativo',
                          style: TextStyle(
                            color: AppColors.destaque,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _AtivoHeroCard(ativo: widget.ativo),
                        const SizedBox(height: 18),

                        _GraficoCard(
                          data: widget.historico,
                          selectedTimePeriod: selectedTimePeriod,
                          onPeriodChanged: (period) {
                            setState(() => selectedTimePeriod = period);
                          },
                        ),

                        const SizedBox(height: 18),

                        _DetalheMetricasCard(
                          ativo: widget.ativo,
                        ),

                        const SizedBox(height: 18),

                        _InfoCard(
                          title: 'Acompanhamento do ativo',
                          children: [
                            _InfoRow(
                              label: 'Preço médio de compra',
                              value:
                              'R\$ ${widget.ativo.precoMedio.toStringAsFixed(2)}',
                            ),
                            _InfoRow(
                              label: 'Preço atual',
                              value:
                              'R\$ ${widget.ativo.valorToken.toStringAsFixed(2)}',
                              destaque: true,
                            ),
                            _InfoRow(
                              label: 'Resultado acumulado',
                              value:
                              '${widget.ativo.lucroPrejuizo >= 0 ? '+' : '-'} R\$ ${widget.ativo.lucroPrejuizo.abs().toStringAsFixed(2)}',
                            ),
                            _InfoRow(
                              label: 'Variação',
                              value:
                              '${_positivo ? '+' : ''}${widget.ativo.variacao.toStringAsFixed(1)}%',
                              destaque: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        Row(
                          children: [
                            Expanded(
                              child: _OutlineActionButton(
                                label: 'Vender',
                                onTap: () => _abrirOrdem(
                                  context,
                                  ModoNegociacao.venda,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _PrimaryActionButton(
                                label: 'Comprar mais',
                                onTap: () => _abrirOrdem(
                                  context,
                                  ModoNegociacao.compra,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _abrirOrdem(BuildContext context, ModoNegociacao modo) {
    final oferta = Oferta(
      tipo: modo == ModoNegociacao.compra
          ? TipoOferta.venda
          : TipoOferta.compra,
      quantidade: widget.ativo.tokens,
      preco: widget.ativo.valorToken,
      empresa: widget.ativo.nome,
      simbolo: widget.ativo.simbolo,
      variacao: widget.ativo.variacao,
      volume: widget.ativo.volume,
      spread: widget.ativo.spread,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrdemExeScreen(
          oferta: oferta,
          modo: modo,
          ofertasDisponiveis: widget.ofertasDisponiveis,
        ),
      ),
    );
  }
}

// ─── Componentes gerais ─────────────────────────────────────────────────────

class _AtmosphericBackground extends StatelessWidget {
  const _AtmosphericBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -110,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.azul.withOpacity(0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 180,
            left: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.destaque.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -100,
            child: Container(
              width: 290,
              height: 290,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.roxo.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.destaque.withOpacity(0.35),
                width: 1.4,
              ),
              gradient: const LinearGradient(
                colors: [
                  AppColors.campo,
                  AppColors.card,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.destaque,
              size: 21,
            ),
          ),
          const Spacer(),
          const Column(
            children: [
              Text(
                'MESCLAINVEST',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.destaque,
                  letterSpacing: 2.4,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Carteira digital',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textoMuitoFraco,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/perfil');
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.bordaClara,
                  width: 1,
                ),
                color: AppColors.card,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.destaque,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 14),
          _HeaderEyebrow(text: 'VISÃO GERAL DA CARTEIRA'),
          SizedBox(height: 14),
          

          Text(
            'Acompanhe seus ativos, saldo disponível e movimentações simuladas.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textoFraco,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderEyebrow extends StatelessWidget {
  final String text;

  const _HeaderEyebrow({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.destaque,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.destaque,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PatrimonioCard extends StatelessWidget {
  final double patrimonioTotal;
  final double saldoDisponivel;
  final int tokensTotais;
  final double variacaoMedia;

  const _PatrimonioCard({
    required this.patrimonioTotal,
    required this.saldoDisponivel,
    required this.tokensTotais,
    required this.variacaoMedia,
  });

  @override
  Widget build(BuildContext context) {
    final positiva = variacaoMedia >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PATRIMÔNIO TOTAL',
              style: TextStyle(
                color: AppColors.textoMuitoFraco,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'R\$ ${patrimonioTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.destaque,
                fontSize: 31,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _ResumoItem(
                    label: 'Saldo disponível',
                    value: 'R\$ ${saldoDisponivel.toStringAsFixed(2)}',
                  ),
                ),
                Expanded(
                  child: _ResumoItem(
                    label: 'Tokens totais',
                    value: '$tokensTotais',
                  ),
                ),
                Expanded(
                  child: _ResumoItem(
                    label: 'Variação',
                    value:
                    '${positiva ? '+' : ''}${variacaoMedia.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  final String label;
  final String value;

  const _ResumoItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textoMuitoFraco,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textoPrincipal,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeaderEyebrow(text: 'VALORIZAÇÃO DA CARTEIRA'),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: LineChartPainter(data: data),
              ),
            ),
            const SizedBox(height: 16),
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
                                ? AppColors.card
                                : AppColors.textoFraco,
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
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final String hint;

  const _SectionLabel({
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textoMuitoFraco,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: const TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _AtivoCard extends StatelessWidget {
  final AtivoCarteira ativo;
  final VoidCallback onTap;

  const _AtivoCard({
    required this.ativo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final negative = ativo.variacao < 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.bordaClara,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.24),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _TickerBox(
              simbolo: ativo.simbolo,
              color: AppColors.destaque,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ativo.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textoPrincipal,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${ativo.tokens} tokens • R\$ ${ativo.valorToken.toStringAsFixed(2)}/token',
                    style: const TextStyle(
                      color: AppColors.textoMuitoFraco,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${ativo.valorTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.textoPrincipal,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${negative ? '' : '+'}${ativo.variacao.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: negative
                        ? AppColors.textoFraco
                        : AppColors.destaque,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AtivoHeroCard extends StatelessWidget {
  final AtivoCarteira ativo;

  const _AtivoHeroCard({
    required this.ativo,
  });

  @override
  Widget build(BuildContext context) {
    final negative = ativo.variacao < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _TickerBox(
            simbolo: ativo.simbolo,
            color: negative ? AppColors.azul : AppColors.destaque,
            size: 62,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ativo.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textoPrincipal,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${ativo.tokens} tokens em carteira',
                  style: const TextStyle(
                    color: AppColors.textoMuitoFraco,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'R\$ ${ativo.valorTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.destaque,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetalheMetricasCard extends StatelessWidget {
  final AtivoCarteira ativo;

  const _DetalheMetricasCard({
    required this.ativo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: _ResumoItem(
              label: 'Tokens',
              value: '${ativo.tokens}',
            ),
          ),
          Expanded(
            child: _ResumoItem(
              label: 'Preço atual',
              value: 'R\$ ${ativo.valorToken.toStringAsFixed(2)}',
            ),
          ),
          Expanded(
            child: _ResumoItem(
              label: 'Variação',
              value:
              '${ativo.variacao >= 0 ? '+' : ''}${ativo.variacao.toStringAsFixed(1)}%',
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.campo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.bordaClara,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderEyebrow(text: title.toUpperCase()),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool destaque;

  const _InfoRow({
    required this.label,
    required this.value,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: destaque
                  ? AppColors.textoPrincipal
                  : AppColors.textoFraco,
              fontSize: destaque ? 14 : 13,
              fontWeight: destaque ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: destaque
                    ? AppColors.destaque
                    : AppColors.textoPrincipal,
                fontSize: destaque ? 16 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.destaqueClaro,
              AppColors.destaqueEscuro,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.destaque.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.card,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlineActionButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.destaque,
          side: const BorderSide(
            color: AppColors.bordaDestaque,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TickerBox extends StatelessWidget {
  final String simbolo;
  final Color color;
  final double size;

  const _TickerBox({
    required this.simbolo,
    required this.color,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.30),
        border: Border.all(
          color: color.withOpacity(0.32),
        ),
      ),
      child: Center(
        child: Text(
          simbolo,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.bordaClara,
        ),
      ),
      child: Row(
        children: [
          Icon(
            entrada ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: AppColors.destaque,
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
                    color: AppColors.textoPrincipal,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  descricao,
                  style: const TextStyle(
                    color: AppColors.textoMuitoFraco,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              color: AppColors.textoPrincipal,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: AppColors.bordaClara,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.32),
        blurRadius: 28,
        offset: const Offset(0, 12),
      ),
    ],
  );
}

// ─── Gráfico ────────────────────────────────────────────────────────────────

class LineChartPainter extends CustomPainter {
  final List<double> data;

  LineChartPainter({
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
    final range = (maxValue - minValue).abs() < 0.01 ? 1.0 : maxValue - minValue;

    final points = <Offset>[];
    final space = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final normalized = (data[i] - minValue) / range;
      final x = i * space;
      final y = size.height - (normalized * size.height * 0.82) - 12;

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
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}