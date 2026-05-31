import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:mescla_invest/models/ativo_carteira.dart';
import 'package:mescla_invest/models/balcao_model.dart';
import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/widgets/shared/app_button.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';
import 'package:mescla_invest/widgets/shared/app_snackbar.dart';
import 'package:mescla_invest/widgets/shared/atmospheric_background.dart';
import 'package:mescla_invest/widgets/shared/info_row.dart';
import 'package:mescla_invest/widgets/shared/section_card.dart';
import 'package:mescla_invest/widgets/shared/ticker_box.dart';
import 'package:mescla_invest/widgets/shared/wallet_chart_card.dart';

import '../ordens/ordem_exe_screen.dart';

class AtivoDetalheScreen extends StatefulWidget {
  final AtivoCarteira ativo;
  final List<Oferta> ofertasDisponiveis;

  const AtivoDetalheScreen({
    super.key,
    required this.ativo,
    required this.ofertasDisponiveis,
  });

  @override
  State<AtivoDetalheScreen> createState() => _AtivoDetalheScreenState();
}

class _AtivoDetalheScreenState extends State<AtivoDetalheScreen> {
  String selectedTimePeriod = '1 mês';

  List<double> _assetChartData = [];
  double _assetStartValue = 0.0;
  double _assetEndValue = 0.0;
  double _assetVariation = 0.0;
  double _assetVariationPercent = 0.0;
  String _assetStartLabel = '';
  String _assetEndLabel = '';
  bool _loadingAssetChart = true;

  int _tokensDisponiveis = 0;
  double _tokenValue = 0.0;
  double _investimentoMinimo = 0.0;
  bool _carregandoDadosStartup = true;

  @override
  void initState() {
    super.initState();
    _loadAssetChart();
    _carregarDadosStartup();
  }

  Future<void> _carregarDadosStartup() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('startups')
          .doc(widget.ativo.startupId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _tokensDisponiveis = (data['tokens'] as num?)?.toInt() ?? 0;
            _tokenValue = (data['tokenValue'] ?? data['minBuyPrice'] as num?)?.toDouble() ?? widget.ativo.valorToken;
            _investimentoMinimo = (data['investimentoMinimo'] ?? data['minInvestment'] as num?)?.toDouble() ?? 0.0;
            _carregandoDadosStartup = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _carregandoDadosStartup = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregandoDadosStartup = false;
        });
      }
    }
  }

  DateTime _periodStartDate(String period) {
    final now = DateTime.now();

    switch (period) {
      case '1h':
        return now.subtract(const Duration(hours: 1));
      case '24h':
        return now.subtract(const Duration(hours: 24));
      case '1 sem':
        return now.subtract(const Duration(days: 7));
      case '1 mês':
        return DateTime(now.year, now.month - 1, now.day, now.hour, now.minute);
      case '6 meses':
        return DateTime(now.year, now.month - 6, now.day, now.hour, now.minute);
      case '1 ano':
        return DateTime(now.year - 1, now.month, now.day, now.hour, now.minute);
      default:
        return DateTime(now.year, now.month - 1, now.day, now.hour, now.minute);
    }
  }

  String _formatDateLabel(DateTime date, String period) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    if (period == '1h' || period == '24h') return '$hour:$minute';

    return '$day/$month';
  }

  bool _isCompraAtivo(Map<String, dynamic> data) {
    final type =
    (data['type'] ??
        data['operationType'] ??
        data['tipo'] ??
        data['method'] ??
        '')
        .toString()
        .toLowerCase();

    return type.contains('purchase') ||
        type.contains('buy') ||
        type.contains('compra') ||
        type.contains('startup_investment');
  }

  bool _isVendaAtivo(Map<String, dynamic> data) {
    final type =
    (data['type'] ??
        data['operationType'] ??
        data['tipo'] ??
        data['method'] ??
        '')
        .toString()
        .toLowerCase();

    return type.contains('sale') ||
        type.contains('sell') ||
        type.contains('venda');
  }

  DateTime? _dataTransacao(Map<String, dynamic> data) {
    final raw = data['createdAt'] ?? data['createAt'] ?? data['created_at'];

    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);

    return null;
  }

  Future<void> _loadAssetChart() async {
    if (!mounted) return;

    setState(() {
      _loadingAssetChart = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final now = DateTime.now();
      final startDate = _periodStartDate(selectedTimePeriod);

      final startLabel = _formatDateLabel(startDate, selectedTimePeriod);
      final endLabel = _formatDateLabel(now, selectedTimePeriod);

      double startValue;
      final endValue = widget.ativo.valorTotal;
      final points = <double>[];

      if (user == null) {
        startValue = widget.ativo.precoMedio * widget.ativo.tokens;
        points.addAll([startValue, endValue]);
      } else {
        final snapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('transacoesCarteira')
            .where('startupId', isEqualTo: widget.ativo.startupId)
            .get();

        final docs = snapshot.docs.toList()
          ..sort((a, b) {
            final dataA =
                _dataTransacao(a.data()) ??
                    DateTime.fromMillisecondsSinceEpoch(0);
            final dataB =
                _dataTransacao(b.data()) ??
                    DateTime.fromMillisecondsSinceEpoch(0);

            return dataA.compareTo(dataB);
          });

        int movimentacaoPeriodo = 0;
        final periodoDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        for (final doc in docs) {
          final data = doc.data();
          final createdAt = _dataTransacao(data);

          if (createdAt == null || createdAt.isBefore(startDate)) continue;

          final quantity =
              ((data['quantity'] ?? data['quantidade']) as num?)?.toInt() ?? 0;

          if (quantity <= 0) continue;

          if (_isCompraAtivo(data)) {
            movimentacaoPeriodo += quantity;
            periodoDocs.add(doc);
          } else if (_isVendaAtivo(data)) {
            movimentacaoPeriodo -= quantity;
            periodoDocs.add(doc);
          }
        }

        int quantidadeInicial = widget.ativo.tokens - movimentacaoPeriodo;

        if (quantidadeInicial < 0) quantidadeInicial = 0;

        if (periodoDocs.isEmpty) {
          startValue = widget.ativo.precoMedio * widget.ativo.tokens;
          points.addAll([startValue, endValue]);
        } else {
          startValue = quantidadeInicial * widget.ativo.valorToken;

          var quantidadeCorrente = quantidadeInicial;
          points.add(startValue);

          for (final doc in periodoDocs) {
            final data = doc.data();

            final quantity =
                ((data['quantity'] ?? data['quantidade']) as num?)?.toInt() ??
                    0;

            if (quantity <= 0) continue;

            if (_isCompraAtivo(data)) {
              quantidadeCorrente += quantity;
            } else if (_isVendaAtivo(data)) {
              quantidadeCorrente -= quantity;
            }

            if (quantidadeCorrente < 0) quantidadeCorrente = 0;

            points.add(quantidadeCorrente * widget.ativo.valorToken);
          }

          if (points.last != endValue) {
            points.add(endValue);
          }
        }
      }

      if (points.length < 2) {
        points.add(endValue);
      }

      final variation = endValue - startValue;
      final variationPercent = startValue > 0
          ? (variation / startValue) * 100
          : 0.0;

      if (!mounted) return;

      setState(() {
        _assetChartData = points;
        _assetStartValue = startValue;
        _assetEndValue = endValue;
        _assetVariation = variation;
        _assetVariationPercent = variationPercent.isFinite
            ? variationPercent
            : 0.0;
        _assetStartLabel = startLabel;
        _assetEndLabel = endLabel;
        _loadingAssetChart = false;
      });
    } catch (_) {
      final startValue = widget.ativo.precoMedio * widget.ativo.tokens;
      final endValue = widget.ativo.valorTotal;
      final variation = endValue - startValue;
      final variationPercent = startValue > 0
          ? (variation / startValue) * 100
          : 0.0;

      if (!mounted) return;

      setState(() {
        _assetChartData = [startValue, endValue];
        _assetStartValue = startValue;
        _assetEndValue = endValue;
        _assetVariation = variation;
        _assetVariationPercent = variationPercent.isFinite
            ? variationPercent
            : 0.0;
        _assetStartLabel = 'Compra';
        _assetEndLabel = 'Atual';
        _loadingAssetChart = false;
      });
    }
  }

  void _trocarPeriodoAtivo(String period) {
    if (period == selectedTimePeriod) return;

    setState(() {
      selectedTimePeriod = period;
    });

    _loadAssetChart();
  }

  Oferta? _selecionarOfertaParaModo(ModoNegociacao modo) {
    final tipoNecessario = modo == ModoNegociacao.compra
        ? TipoOferta.venda
        : TipoOferta.compra;

    final ofertasValidas = widget.ofertasDisponiveis
        .where(
          (oferta) => oferta.tipo == tipoNecessario && oferta.quantidade > 0,
    )
        .toList();

    if (ofertasValidas.isEmpty) return null;

    ofertasValidas.sort((a, b) {
      if (modo == ModoNegociacao.compra) {
        return a.preco.compareTo(b.preco);
      }

      return b.preco.compareTo(a.preco);
    });

    return ofertasValidas.first;
  }

  void _abrirOrdem(BuildContext context, ModoNegociacao modo) {
    final oferta = _selecionarOfertaParaModo(modo);

    if (oferta == null) {
      final mensagem = modo == ModoNegociacao.compra
          ? 'Nenhuma oferta de venda disponível para compra.'
          : 'Nenhuma oferta de compra disponível para venda.';

      AppSnackBar.show(context, message: mensagem, error: true);

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrdemExeScreen(
          oferta: oferta,
          modo: modo,
          ofertasDisponiveis: widget.ofertasDisponiveis,
          quantidadeMaximaUsuario: modo == ModoNegociacao.venda ? widget.ativo.tokens : null,
        ),
      ),
    );
  }

  void _abrirCompraDireta(BuildContext context) {
    if (_tokensDisponiveis <= 0) {
      AppSnackBar.show(context, message: 'Não há tokens disponíveis para esta startup.', error: true);
      return;
    }

    final ofertaSimulada = Oferta(
      id: 'direct-${widget.ativo.startupId}',
      startupId: widget.ativo.startupId,
      quantidade: _tokensDisponiveis,
      preco: _tokenValue > 0 ? _tokenValue : widget.ativo.valorToken,
      tipo: TipoOferta.venda,
      isStartup: true,
      empresa: widget.ativo.nome,
      simbolo: widget.ativo.simbolo,
      variacao: 0.0,
      volume: '$_tokensDisponiveis',
      spread: 0.4,
      minBuyPrice: _tokenValue > 0 ? _tokenValue : widget.ativo.valorToken,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrdemExeScreen(
          oferta: ofertaSimulada,
          modo: ModoNegociacao.compra,
          ofertasDisponiveis: [ofertaSimulada],
          quantidadeMaximaUsuario: null,
          investimentoMinimo: _investimentoMinimo,
          compraDireto: true,
        ),
      ),
    );
  }

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
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.destaque,
                            size: 20,
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _AtivoHeroCard(ativo: widget.ativo),
                      const SizedBox(height: 18),
                      _loadingAssetChart
                          ? Container(
                        height: 260,
                        decoration: premiumCardDecoration(),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.destaque,
                          ),
                        ),
                      )
                          : WalletChartCard(
                        data: _assetChartData,
                        selectedTimePeriod: selectedTimePeriod,
                        startValue: _assetStartValue,
                        endValue: _assetEndValue,
                        variation: _assetVariation,
                        variationPercent: _assetVariationPercent,
                        startLabel: _assetStartLabel,
                        endLabel: _assetEndLabel,
                        horizontalPadding: 0,
                        onPeriodChanged: _trocarPeriodoAtivo,
                      ),
                      const SizedBox(height: 18),
                      _DetalheMetricasCard(
                        ativo: widget.ativo,
                        variacaoPeriodo: _assetVariationPercent,
                        resultadoPeriodo: _assetVariation,
                      ),
                      const SizedBox(height: 18),
                      SectionCard(
                        title: 'Acompanhamento do ativo',
                        child: Column(
                          children: [
                            InfoRow(
                              label: 'Preço médio de compra',
                              value:
                              'R\$ ${widget.ativo.precoMedio.toStringAsFixed(2)}',
                              boxed: true,
                            ),
                            const SizedBox(height: 10),
                            InfoRow(
                              label: 'Preço atual',
                              value:
                              'R\$ ${widget.ativo.valorToken.toStringAsFixed(2)}',
                              destaque: true,
                              boxed: true,
                            ),
                            const SizedBox(height: 10),
                            InfoRow(
                              label: 'Resultado no período',
                              value:
                              '${_assetVariation >= 0 ? '+' : '-'} R\$ ${_assetVariation.abs().toStringAsFixed(2)}',
                              boxed: true,
                            ),
                            const SizedBox(height: 10),
                            InfoRow(
                              label: 'Variação no período',
                              value:
                              '${_assetVariation >= 0 ? '+' : ''}${_assetVariationPercent.toStringAsFixed(1)}%',
                              destaque: true,
                              boxed: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.outline(
                              label: 'Vender',
                              onTap: () =>
                                  _abrirOrdem(context, ModoNegociacao.venda),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton.primary(
                              label: 'Comprar mais',
                              loading: _carregandoDadosStartup,
                              onTap: _carregandoDadosStartup 
                                  ? null 
                                  : () => _abrirCompraDireta(context),
                            ),
                          ),
                        ],
                      ),
                    ]),
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

class _AtivoHeroCard extends StatelessWidget {
  final AtivoCarteira ativo;

  const _AtivoHeroCard({required this.ativo});

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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${ativo.tokens} tokens em carteira',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'R\$ ${ativo.valorTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.destaque,
                    fontWeight: FontWeight.w800,
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
  final double variacaoPeriodo;
  final double resultadoPeriodo;

  const _DetalheMetricasCard({
    required this.ativo,
    required this.variacaoPeriodo,
    required this.resultadoPeriodo,
  });

  @override
  Widget build(BuildContext context) {
    final resultadoPositivo = resultadoPeriodo >= 0;

    return Container(
      decoration: premiumCardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DetailMetricItem(
                  label: 'Tokens',
                  value: '${ativo.tokens}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DetailMetricItem(
                  label: 'Preço atual',
                  value: 'R\$ ${ativo.valorToken.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DetailMetricItem(
                  label: 'Preço médio',
                  value: 'R\$ ${ativo.precoMedio.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DetailMetricItem(
                  label: 'Resultado',
                  value:
                  '${resultadoPositivo ? '+' : '-'} R\$ ${resultadoPeriodo.abs().toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DetailMetricItem(
                  label: 'Variação',
                  value:
                  '${resultadoPositivo ? '+' : ''}${variacaoPeriodo.toStringAsFixed(1)}%',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DetailMetricItem(
                  label: 'Valor total',
                  value: 'R\$ ${ativo.valorTotal.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailMetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailMetricItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: premiumFieldDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textoPrincipal,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}