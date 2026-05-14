import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mescla_invest/services/carteira_service.dart';
import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/widgets/app_bar_padrao.dart';
import 'package:mescla_invest/widgets/bottom_nav_bar.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';

import 'package:mescla_invest/widgets/shared/atmospheric_background.dart';
import 'package:mescla_invest/widgets/shared/empty_state_card.dart';
import 'package:mescla_invest/widgets/shared/gradient_button.dart';
import 'package:mescla_invest/widgets/shared/icon_box.dart';
import 'package:mescla_invest/widgets/shared/info_row.dart';
import 'package:mescla_invest/widgets/shared/outline_button.dart' as shared;
import 'package:mescla_invest/widgets/shared/section_card.dart';
import 'package:mescla_invest/widgets/shared/section_label.dart';
import 'package:mescla_invest/widgets/shared/ticker_box.dart';

import '../../models/balcao_model.dart';
import '../ordens/ordem_exe_screen.dart';
import 'adicionar_fundos_screen.dart';

class CarteiraPage extends StatefulWidget {
  const CarteiraPage({super.key});

  @override
  State<CarteiraPage> createState() => _CarteiraPageState();
}

class _CarteiraPageState extends State<CarteiraPage> {
  String selectedTimePeriod = '1 mês';

  List<double> _chartData = [];

  double _saldo = 0.0;
  List<AtivoCarteira> _ativos = [];
  List<Map<String, dynamic>> _movimentacoes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _abrirAdicionarFundos() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdicionarFundosScreen(),
      ),
    );

    if (resultado == true) {
      await _loadData();
    }
  }

  Future<void> _trocarPeriodoGrafico(String period) async {
    if (period == selectedTimePeriod) return;

    setState(() {
      selectedTimePeriod = period;
      _loading = true;
    });

    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      final carteiraService = CarteiraService();
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        if (mounted) {
          setState(() => _loading = false);
        }
        return;
      }

      final saldo = await carteiraService.getBalance();
      final tokensMap = await carteiraService.getTokens();

      final List<AtivoCarteira> ativosTemp = [];
      final firestore = FirebaseFirestore.instance;

      for (final entry in tokensMap.entries) {
        final startupId = entry.key;
        final quantidade = entry.value;

        if ((quantidade as num) > 0) {
          final doc = await firestore
              .collection('startups')
              .doc(startupId)
              .get();

          if (doc.exists) {
            final data = doc.data()!;
            final title = data['title'] ?? data['nome'] ?? 'Startup';
            final tokenValue =
            ((data['tokenValue'] ?? data['valorToken'] ?? 0.0) as num)
                .toDouble();

            ativosTemp.add(
              AtivoCarteira(
                nome: title,
                simbolo: _gerarSimbolo(title),
                tokens: quantidade.toInt(),
                valorToken: tokenValue,
                precoMedio: tokenValue,
                variacao: 0.0,
                volume: '0',
                spread: 0.0,
              ),
            );
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

      final transacoesCarteira = await firestore
          .collection('usuarios')
          .doc(uid)
          .collection('transacoesCarteira')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final todasMovs = <Map<String, dynamic>>[
        ...compras.docs.map(
              (doc) => {
            ...doc.data(),
            '_origem': 'balcao',
          },
        ),
        ...vendas.docs.map(
              (doc) => {
            ...doc.data(),
            '_origem': 'balcao',
          },
        ),
        ...transacoesCarteira.docs.map(
              (doc) => {
            ...doc.data(),
            '_origem': 'carteira',
          },
        ),
      ];

      todasMovs.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];

        if (aDate is Timestamp && bDate is Timestamp) {
          return bDate.compareTo(aDate);
        }

        return 0;
      });

      final movsTemp = todasMovs.take(5).toList();

      List<double> chartData = [];

      try {
        chartData = await carteiraService.getWalletChartValues(
          periodo: selectedTimePeriod,
        );
      } catch (_) {
        chartData = [];
      }

      final valorAtivos = ativosTemp.fold<double>(
        0,
            (total, ativo) => total + ativo.valorTotal,
      );

      final patrimonioAtual = saldo + valorAtivos;

      final fallbackChartData = chartData.length >= 2
          ? chartData
          : [
        saldo,
        patrimonioAtual,
      ];

      if (mounted) {
        setState(() {
          _saldo = saldo;
          _ativos = ativosTemp;
          _movimentacoes = movsTemp;
          _chartData = fallbackChartData;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  static String _gerarSimbolo(String nome) {
    final palavras = nome
        .replaceAll(RegExp(r'[^a-zA-ZÀ-ÿ0-9 ]'), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (palavras.isEmpty) return 'STP';

    if (palavras.length == 1) {
      final palavra = palavras.first;
      return palavra.substring(0, math.min(3, palavra.length)).toUpperCase();
    }

    return palavras.take(3).map((p) => p[0]).join().toUpperCase();
  }

  double get patrimonioTotal {
    final totalAtivos = _ativos.fold<double>(
      0,
          (total, ativo) => total + ativo.valorTotal,
    );

    return _saldo + totalAtivos;
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

  String _tituloMovimentacao(Map<String, dynamic> mov) {
    final origem = mov['_origem'];

    if (origem == 'carteira') {
      final type = mov['type'] ?? 'deposit';

      switch (type) {
        case 'deposit':
          return 'Depósito via Pix simulado';
        case 'purchase':
          return 'Compra de tokens';
        case 'sale':
          return 'Venda de tokens';
        case 'withdraw':
          return 'Saque simulado';
        default:
          return 'Movimentação da carteira';
      }
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isBuy = mov['buyerId'] == uid;

    return isBuy ? 'Compra executada' : 'Venda executada';
  }

  String _descricaoMovimentacao(Map<String, dynamic> mov) {
    final origem = mov['_origem'];

    if (origem == 'carteira') {
      final description = mov['description'];

      if (description is String && description.trim().isNotEmpty) {
        return description;
      }

      return 'Movimentação financeira simulada';
    }

    final quantity = mov['quantity'] ?? 0;
    return '$quantity tokens';
  }

  String _valorMovimentacao(Map<String, dynamic> mov) {
    final origem = mov['_origem'];

    if (origem == 'carteira') {
      final amount = (mov['amount'] as num?)?.toDouble() ?? 0.0;
      final sinal = amount >= 0 ? '+' : '-';

      return '$sinal R\$ ${amount.abs().toStringAsFixed(2)}';
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isBuy = mov['buyerId'] == uid;
    final totalPrice = (mov['totalPrice'] as num?)?.toDouble() ?? 0.0;

    return '${isBuy ? '-' : '+'} R\$ ${totalPrice.toStringAsFixed(2)}';
  }

  IconData _iconeMovimentacao(Map<String, dynamic> mov) {
    final origem = mov['_origem'];

    if (origem == 'carteira') {
      final type = mov['type'] ?? 'deposit';

      switch (type) {
        case 'deposit':
          return Icons.pix_rounded;
        case 'purchase':
          return Icons.shopping_bag_rounded;
        case 'sale':
          return Icons.sell_rounded;
        case 'withdraw':
          return Icons.account_balance_rounded;
        default:
          return Icons.receipt_long_rounded;
      }
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isBuy = mov['buyerId'] == uid;

    return isBuy ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.fundo,
        extendBody: true,
        appBar: const AppBarPadrao(titulo: 'Minha Carteira'),
        bottomNavigationBar: const BottomNavBar(selectedIndex: 2),
        body: Stack(
          children: [
            const AtmosphericBackground(),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.destaque,
                ),
              )
            else
              SafeArea(
                bottom: false,
                child: RefreshIndicator(
                  color: AppColors.destaque,
                  backgroundColor: AppColors.card,
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
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
                          onAdicionarFundos: _abrirAdicionarFundos,
                        ),
                      ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 18),
                      ),

                      SliverToBoxAdapter(
                        child: _GraficoCard(
                          data: _chartData,
                          selectedTimePeriod: selectedTimePeriod,
                          onPeriodChanged: _trocarPeriodoGrafico,
                        ),
                      ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),

                      const SliverToBoxAdapter(
                        child: SectionLabel(
                          label: 'SEUS ATIVOS',
                          hint:
                          'Acompanhe seus tokens e a valorização por startup.',
                        ),
                      ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 12),
                      ),

                      if (_ativos.isEmpty)
                        const SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 22),
                          sliver: SliverToBoxAdapter(
                            child: EmptyStateCard(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'Nenhum ativo em carteira',
                              message:
                              'Quando você comprar tokens, eles aparecerão aqui.',
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          sliver: SliverList.separated(
                            itemCount: _ativos.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
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
                                        historico: _chartData,
                                        ofertasDisponiveis:
                                        _ofertasDoAtivo(ativo),
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
                        child: SectionLabel(
                          label: 'ÚLTIMAS MOVIMENTAÇÕES',
                          hint:
                          'Histórico recente das operações e aportes simulados.',
                        ),
                      ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 12),
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        sliver: _movimentacoes.isEmpty
                            ? const SliverToBoxAdapter(
                          child: EmptyStateCard(
                            icon: Icons.receipt_long_outlined,
                            title: 'Nenhuma movimentação recente',
                            message:
                            'Seus aportes, compras e vendas aparecerão aqui.',
                          ),
                        )
                            : SliverList.separated(
                          itemCount: _movimentacoes.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final mov = _movimentacoes[index];

                            return _MovimentacaoTile(
                              titulo: _tituloMovimentacao(mov),
                              descricao: _descricaoMovimentacao(mov),
                              valor: _valorMovimentacao(mov),
                              icon: _iconeMovimentacao(mov),
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
      backgroundColor: AppColors.fundo,
      body: Stack(
        children: [
          const AtmosphericBackground(),
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
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
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

                        SectionCard(
                          title: 'Acompanhamento do ativo',
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: premiumFieldDecoration(
                              radius: 18,
                            ),
                            child: Column(
                              children: [
                                InfoRow(
                                  label: 'Preço médio de compra',
                                  value:
                                  'R\$ ${widget.ativo.precoMedio.toStringAsFixed(2)}',
                                ),
                                InfoRow(
                                  label: 'Preço atual',
                                  value:
                                  'R\$ ${widget.ativo.valorToken.toStringAsFixed(2)}',
                                  destaque: true,
                                ),
                                InfoRow(
                                  label: 'Resultado acumulado',
                                  value:
                                  '${widget.ativo.lucroPrejuizo >= 0 ? '+' : '-'} R\$ ${widget.ativo.lucroPrejuizo.abs().toStringAsFixed(2)}',
                                ),
                                InfoRow(
                                  label: 'Variação',
                                  value:
                                  '${_positivo ? '+' : ''}${widget.ativo.variacao.toStringAsFixed(1)}%',
                                  destaque: true,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        Row(
                          children: [
                            Expanded(
                              child: shared.OutlineButton(
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
                              child: GradientButton(
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

// ─── Componentes específicos da carteira ────────────────────────────────────

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
          PremiumHeaderEyebrow(text: 'VISÃO GERAL DA CARTEIRA'),
          SizedBox(height: 14),
          Text(
            'Acompanhe seus ativos, saldo disponível e movimentações simuladas.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textoFraco,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatrimonioCard extends StatelessWidget {
  final double patrimonioTotal;
  final double saldoDisponivel;
  final int tokensTotais;
  final double variacaoMedia;
  final VoidCallback onAdicionarFundos;

  const _PatrimonioCard({
    required this.patrimonioTotal,
    required this.saldoDisponivel,
    required this.tokensTotais,
    required this.variacaoMedia,
    required this.onAdicionarFundos,
  });

  @override
  Widget build(BuildContext context) {
    final positiva = variacaoMedia >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: premiumCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PremiumSectionLabel(text: 'Patrimônio total'),
            const SizedBox(height: 14),
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
            const SizedBox(height: 18),
            GradientButton(
              label: 'Adicionar fundos',
              icon: Icons.add_card_rounded,
              onTap: onAdicionarFundos,
              height: 54,
              radius: 18,
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
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: premiumFieldDecoration(
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textoPrincipal,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
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
    final chartData = data.length >= 2 ? data : [0.0, 0.0];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: premiumCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PremiumHeaderEyebrow(text: 'VALORIZAÇÃO DA CARTEIRA'),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: LineChartPainter(data: chartData),
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

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: premiumCardDecoration(
            radius: 22,
          ),
          child: Row(
            children: [
              TickerBox(
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
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${ativo.valorTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.textoPrincipal,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${negative ? '' : '+'}${ativo.variacao.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color:
                      negative ? AppColors.textoFraco : AppColors.destaque,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      decoration: premiumCardDecoration(),
      child: Row(
        children: [
          TickerBox(
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
      decoration: premiumCardDecoration(),
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

class _MovimentacaoTile extends StatelessWidget {
  final String titulo;
  final String descricao;
  final String valor;
  final IconData icon;

  const _MovimentacaoTile({
    required this.titulo,
    required this.descricao,
    required this.valor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final entrada = valor.startsWith('+');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: premiumCardDecoration(
        radius: 18,
      ),
      child: Row(
        children: [
          IconBox(
            icon: icon,
            size: 34,
            iconSize: 18,
            radius: 12,
            color: entrada ? AppColors.destaque : AppColors.textoFraco,
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
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  descricao,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textoMuitoFraco,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            valor,
            style: TextStyle(
              color: entrada ? AppColors.destaque : AppColors.textoPrincipal,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
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
    final range =
    (maxValue - minValue).abs() < 0.01 ? 1.0 : maxValue - minValue;

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