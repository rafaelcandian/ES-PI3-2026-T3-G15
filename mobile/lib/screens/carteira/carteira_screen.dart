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
  List<Map<String, dynamic>> _chartPoints = [];
  double _chartStartValue = 0.0;
  double _chartEndValue = 0.0;
  double _chartVariation = 0.0;
  double _chartVariationPercent = 0.0;
  String _chartStartLabel = '';
  String _chartEndLabel = '';

  double _saldo = 0.0;
  List<AtivoCarteira> _ativos = [];
  List<Map<String, dynamic>> _movimentacoes = [];
  bool _loading = true;
  bool _ocultarValores = false;

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

      // Atualiza o saldo assim que ele é lido do Firestore.
      // Assim, mesmo que gráfico, transações ou ativos deem erro,
      // o saldo da carteira aparece corretamente na tela.
      if (mounted) {
        setState(() {
          _saldo = saldo;
        });
      }

      final tokensMap = await carteiraService.getTokens();

      final List<AtivoCarteira> ativosTemp = [];
      final firestore = FirebaseFirestore.instance;

      for (final entry in tokensMap.entries) {
        final startupId = entry.key;
        final quantidade = entry.value;

        if ((quantidade as num) > 0) {
          final doc = await firestore.collection('startups').doc(startupId).get();

          if (doc.exists) {
            final data = doc.data()!;

            final title = data['title'] ?? data['nome'] ?? 'Startup';

            final tokenValue =
                ((data['tokenValue'] ?? data['valorToken'] ?? 0.0) as num)
                    .toDouble();

            final precoMedio = await _calcularPrecoMedio(
              firestore: firestore,
              uid: uid,
              startupId: startupId,
              fallback: tokenValue,
            );

            final variacaoInformada = ((data['variacao'] ??
                        data['variation'] ??
                        data['variacaoPercentual'] ??
                        0.0)
                    as num)
                .toDouble();

            final variacaoCalculada = precoMedio > 0
                ? ((tokenValue - precoMedio) / precoMedio) * 100
                : variacaoInformada;

            final variacao = variacaoCalculada.isFinite
                ? variacaoCalculada
                : variacaoInformada;

            final volume = (data['volume'] ??
                    data['volumeNegociado'] ??
                    data['volumeTotal'] ??
                    'Não informado')
                .toString();

            final spread = ((data['spread'] ?? 0.0) as num).toDouble();

            ativosTemp.add(
              AtivoCarteira(
                startupId: startupId,
                nome: title,
                simbolo: _gerarSimbolo(title),
                tokens: quantidade.toInt(),
                valorToken: tokenValue,
                precoMedio: precoMedio,
                variacao: variacao,
                volume: volume,
                spread: spread,
              ),
            );
          }
        }
      }

      List<Map<String, dynamic>> movsTemp = [];

      try {
        // Lê apenas o histórico próprio da carteira.
        // Isso evita duplicidade entre `transactions` e `transacoesCarteira`,
        // porque algumas compras também geram documento em `transactions`.
        final transacoesCarteira = await firestore
            .collection('usuarios')
            .doc(uid)
            .collection('transacoesCarteira')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();

        movsTemp = transacoesCarteira.docs.map(
          (doc) => {
            ...doc.data(),
            'id': doc.id,
            '_origem': 'carteira',
          },
        ).toList();
      } catch (e) {
        print('Erro ao carregar movimentações: $e');
      }

      List<Map<String, dynamic>> chartPoints = [];
      List<double> chartData = [];

      try {
        chartPoints = await carteiraService.getWalletChartPoints(
          periodo: selectedTimePeriod,
        );

        chartData = chartPoints
            .map((point) => (point['value'] as num?)?.toDouble() ?? 0.0)
            .where((value) => value > 0)
            .toList();
      } catch (e) {
        print('Erro ao carregar gráfico da carteira: $e');
        chartPoints = [];
        chartData = [];
      }

      final resumoGrafico = _calcularResumoGrafico(
        chartPoints: chartPoints,
        chartData: chartData,
      );

      if (mounted) {
        setState(() {
          _saldo = saldo;
          _ativos = ativosTemp;
          _movimentacoes = movsTemp;
          _chartPoints = chartPoints;
          _chartData = chartData;
          _chartStartValue = resumoGrafico['startValue'] as double;
          _chartEndValue = resumoGrafico['endValue'] as double;
          _chartVariation = resumoGrafico['variation'] as double;
          _chartVariationPercent = resumoGrafico['variationPercent'] as double;
          _chartStartLabel = resumoGrafico['startLabel'] as String;
          _chartEndLabel = resumoGrafico['endLabel'] as String;
          _loading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar carteira: $e');

      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Map<String, dynamic> _calcularResumoGrafico({
    required List<Map<String, dynamic>> chartPoints,
    required List<double> chartData,
  }) {
    if (chartData.isEmpty) {
      return {
        'startValue': 0.0,
        'endValue': 0.0,
        'variation': 0.0,
        'variationPercent': 0.0,
        'startLabel': '',
        'endLabel': '',
      };
    }

    final startValue = chartData.first;
    final endValue = chartData.last;
    final variation = endValue - startValue;
    final variationPercent = startValue > 0 ? (variation / startValue) * 100 : 0.0;

    String startLabel = '';
    String endLabel = '';

    if (chartPoints.isNotEmpty) {
      startLabel = (chartPoints.first['label'] ?? '').toString();
      endLabel = (chartPoints.last['label'] ?? '').toString();
    }

    return {
      'startValue': startValue,
      'endValue': endValue,
      'variation': variation,
      'variationPercent': variationPercent.isFinite ? variationPercent : 0.0,
      'startLabel': startLabel,
      'endLabel': endLabel,
    };
  }

  Future<double> _calcularPrecoMedio({
    required FirebaseFirestore firestore,
    required String uid,
    required String startupId,
    required double fallback,
  }) async {
    double totalInvestido = 0;
    int totalTokens = 0;

    // Fonte principal: histórico próprio da carteira.
    // Aqui entram compras diretas, compras via balcão e registros antigos.
    final historicoCarteira = await firestore
        .collection('usuarios')
        .doc(uid)
        .collection('transacoesCarteira')
        .where('startupId', isEqualTo: startupId)
        .get();

    for (final doc in historicoCarteira.docs) {
      final data = doc.data();

      final type = (data['type'] ??
              data['operationType'] ??
              data['tipo'] ??
              data['method'] ??
              '')
          .toString()
          .toLowerCase();

      final isCompra = type.contains('purchase') ||
          type.contains('buy') ||
          type.contains('compra') ||
          type.contains('startup_investment');

      if (!isCompra) continue;

      final quantidade =
          ((data['quantity'] ?? data['quantidade']) as num?)?.toInt() ?? 0;

      final precoUnitario =
          ((data['pricePerToken'] ?? data['precoUnitario']) as num?)
                  ?.toDouble() ??
              0.0;

      final totalPrice =
          ((data['totalPrice'] ?? data['total'] ?? data['valor']) as num?)
                  ?.toDouble() ??
              0.0;

      if (quantidade > 0 && precoUnitario > 0) {
        totalTokens += quantidade;
        totalInvestido += quantidade * precoUnitario;
      } else if (quantidade > 0 && totalPrice > 0) {
        totalTokens += quantidade;
        totalInvestido += totalPrice;
      }
    }

    // Fallback: coleção global transactions, usada por algumas Functions.
    // Mantém compatibilidade com registros antigos.
    if (totalTokens == 0) {
      final compras = await firestore
          .collection('transactions')
          .where('buyerId', isEqualTo: uid)
          .where('startupId', isEqualTo: startupId)
          .get();

      for (final doc in compras.docs) {
        final data = doc.data();

        final quantidade = (data['quantity'] as num?)?.toInt() ?? 0;
        final precoUnitario = (data['pricePerToken'] as num?)?.toDouble() ?? 0.0;
        final totalPrice = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;

        if (quantidade > 0 && precoUnitario > 0) {
          totalTokens += quantidade;
          totalInvestido += quantidade * precoUnitario;
        } else if (quantidade > 0 && totalPrice > 0) {
          totalTokens += quantidade;
          totalInvestido += totalPrice;
        }
      }
    }

    if (totalTokens == 0) return fallback;

    return totalInvestido / totalTokens;
  }

  Future<List<Oferta>> _buscarOfertasDoAtivo(AtivoCarteira ativo) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('startupId', isEqualTo: ativo.startupId)
          .where('status', isEqualTo: 'open')
          .get();

      final ofertas = snapshot.docs.map((doc) {
        final data = doc.data();
        final tipo = data['type'] == 'buy'
            ? TipoOferta.compra
            : TipoOferta.venda;

        return Oferta(
          tipo: tipo,
          quantidade: (data['quantity'] as num?)?.toInt() ?? 0,
          preco: (data['pricePerToken'] as num?)?.toDouble()
              ?? ativo.valorToken,
          empresa: ativo.nome,
          simbolo: ativo.simbolo,
          variacao: ativo.variacao,
          volume: ativo.volume,
          spread: ativo.spread,
          startupId: ativo.startupId,
          minBuyPrice: ativo.valorToken,
        );
      }).toList();

      ofertas.sort((a, b) => a.preco.compareTo(b.preco));
      return ofertas;
    } catch (e) {
      print('Erro ao buscar ofertas do ativo: $e');
      return [];
    }
  }

  Future<void> _abrirDetalheAtivo(AtivoCarteira ativo) async {
    try {
      final ofertas = await _buscarOfertasDoAtivo(ativo);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AtivoDetalheScreen(
            ativo: ativo,
            historico: _chartData,
            ofertasDisponiveis: ofertas,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar as ofertas deste ativo.'),
        ),
      );
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

  String _normalizarTipoMovimentacao(Map<String, dynamic> mov) {
    final type = (mov['type'] ??
            mov['operationType'] ??
            mov['tipo'] ??
            mov['method'] ??
            '')
        .toString()
        .toLowerCase();

    if (type.contains('deposit') ||
        type.contains('aporte') ||
        type.contains('pix') ||
        type.contains('fund')) {
      return 'deposit';
    }

    if (type.contains('sale') || type.contains('sell') || type.contains('venda')) {
      return 'sale';
    }

    if (type.contains('purchase') ||
        type.contains('buy') ||
        type.contains('compra') ||
        type.contains('startup_investment')) {
      return 'purchase';
    }

    return 'movimentacao';
  }

  Timestamp? _timestampMovimentacao(Map<String, dynamic> mov) {
    final valor = mov['createdAt'] ??
        mov['createAt'] ??
        mov['created_at'] ??
        mov['criado_em'];

    return valor is Timestamp ? valor : null;
  }

  String _dataMovimentacao(Map<String, dynamic> mov) {
    final timestamp = _timestampMovimentacao(mov);

    if (timestamp == null) return 'Data indisponível';

    final data = timestamp.toDate();
    final agora = DateTime.now();

    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    final mesmoDia = data.year == agora.year &&
        data.month == agora.month &&
        data.day == agora.day;

    if (mesmoDia) return 'Hoje às $hora:$minuto';

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes às $hora:$minuto';
  }

  String _tituloMovimentacao(Map<String, dynamic> mov) {
    final tipo = _normalizarTipoMovimentacao(mov);

    switch (tipo) {
      case 'deposit':
        return 'Adição de saldo';
      case 'purchase':
        return 'Compra de tokens';
      case 'sale':
        return 'Venda de tokens';
      default:
        return 'Movimentação da carteira';
    }
  }

  String _descricaoMovimentacao(Map<String, dynamic> mov) {
    final tipo = _normalizarTipoMovimentacao(mov);
    final ticker = (mov['ticker'] ?? mov['simbolo'] ?? '').toString();
    final startupName = (mov['startupName'] ??
            mov['startupNome'] ??
            mov['empresa'] ??
            mov['startup'] ??
            '')
        .toString();
    final quantityValue = mov['quantity'] ?? mov['quantidade'];
    final quantity = (quantityValue as num?)?.toInt() ?? 0;
    final data = _dataMovimentacao(mov);

    if (tipo == 'deposit') {
      return 'Pix simulado • $data';
    }

    final partes = <String>[];

    if (ticker.trim().isNotEmpty) {
      partes.add(ticker.trim());
    } else if (startupName.trim().isNotEmpty) {
      partes.add(startupName.trim());
    }

    if (quantity > 0) {
      partes.add('$quantity tokens');
    }

    partes.add(data);

    return partes.join(' • ');
  }

  String _valorMovimentacao(Map<String, dynamic> mov) {
    final tipo = _normalizarTipoMovimentacao(mov);
    final amount = (mov['amount'] as num?)?.toDouble();

    double valor;

    if (amount != null && amount != 0) {
      valor = amount.abs();
    } else {
      valor = ((mov['totalPrice'] ??
                  mov['total'] ??
                  mov['totalFinal'] ??
                  mov['valor'] ??
                  0.0) as num)
              .toDouble()
              .abs();
    }

    final entrada = tipo == 'deposit' || tipo == 'sale';

    return '${entrada ? '+' : '-'} R\$ ${valor.toStringAsFixed(2)}';
  }

  IconData _iconeMovimentacao(Map<String, dynamic> mov) {
    final tipo = _normalizarTipoMovimentacao(mov);

    switch (tipo) {
      case 'deposit':
        return Icons.account_balance_wallet_rounded;
      case 'purchase':
        return Icons.shopping_bag_rounded;
      case 'sale':
        return Icons.sell_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  Color _corMovimentacao(Map<String, dynamic> mov) {
  final tipo = _normalizarTipoMovimentacao(mov);

  switch (tipo) {
    case 'deposit':
      return AppColors.destaque;

    // VENDA = vermelho
    case 'sale':
      return const Color(0xFFF87171);

    // COMPRA = azul/dourado do app
    case 'purchase':
      return AppColors.azul;

    default:
      return AppColors.textoMuitoFraco;
  }
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
                          ocultarValores: _ocultarValores,
                          onToggleOcultarValores: () {
                            setState(() {
                              _ocultarValores = !_ocultarValores;
                            });
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 18),
                      ),
                      SliverToBoxAdapter(
                        child: _GraficoCard(
                          data: _chartData,
                          points: _chartPoints,
                          selectedTimePeriod: selectedTimePeriod,
                          startValue: _chartStartValue,
                          endValue: _chartEndValue,
                          variation: _chartVariation,
                          variationPercent: _chartVariationPercent,
                          startLabel: _chartStartLabel,
                          endLabel: _chartEndLabel,
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
                                onTap: () => _abrirDetalheAtivo(ativo),
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
                          hint: 'Histórico recente das operações e aportes.',
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
                              cor: _corMovimentacao(mov),
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
}

// ─── Modelo interno da carteira ─────────────────────────────────────────────

class AtivoCarteira {
  final String startupId;
  final String nome;
  final String simbolo;
  final int tokens;
  final double valorToken;
  final double precoMedio;
  final double variacao;
  final String volume;
  final double spread;

  const AtivoCarteira({
    required this.startupId,
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

  List<double> _assetChartData = [];
  double _assetStartValue = 0.0;
  double _assetEndValue = 0.0;
  double _assetVariation = 0.0;
  double _assetVariationPercent = 0.0;
  String _assetStartLabel = '';
  String _assetEndLabel = '';
  bool _loadingAssetChart = true;

  bool get _positivo => _assetVariation >= 0;

  @override
  void initState() {
    super.initState();
    _loadAssetChart();
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

    if (period == '1h' || period == '24h') {
      return '$hour:$minute';
    }

    return '$day/$month';
  }

  bool _isCompraAtivo(Map<String, dynamic> data) {
    final type = (data['type'] ??
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
    final type = (data['type'] ??
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
      double endValue = widget.ativo.valorTotal;
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
            final dataA = _dataTransacao(a.data()) ?? DateTime.fromMillisecondsSinceEpoch(0);
            final dataB = _dataTransacao(b.data()) ?? DateTime.fromMillisecondsSinceEpoch(0);
            return dataA.compareTo(dataB);
          });

        int movimentacaoPeriodo = 0;
        final periodoDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        for (final doc in docs) {
          final data = doc.data();
          final createdAt = _dataTransacao(data);
          if (createdAt == null || createdAt.isBefore(startDate)) continue;

          final quantity = ((data['quantity'] ?? data['quantidade']) as num?)?.toInt() ?? 0;
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

        // Se não houve compra/venda no período, usamos o preço médio como referência.
        // Assim o detalhe mostra lucro/prejuízo real do ativo: preço médio pago x preço atual.
        if (periodoDocs.isEmpty) {
          startValue = widget.ativo.precoMedio * widget.ativo.tokens;
          points.addAll([startValue, endValue]);
        } else {
          startValue = quantidadeInicial * widget.ativo.valorToken;
          var quantidadeCorrente = quantidadeInicial;

          points.add(startValue);

          for (final doc in periodoDocs) {
            final data = doc.data();
            final quantity = ((data['quantity'] ?? data['quantidade']) as num?)?.toInt() ?? 0;
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
      final variationPercent = startValue > 0 ? (variation / startValue) * 100 : 0.0;

      if (!mounted) return;

      setState(() {
        _assetChartData = points;
        _assetStartValue = startValue;
        _assetEndValue = endValue;
        _assetVariation = variation;
        _assetVariationPercent = variationPercent.isFinite ? variationPercent : 0.0;
        _assetStartLabel = startLabel;
        _assetEndLabel = endLabel;
        _loadingAssetChart = false;
      });
    } catch (e) {
      final startValue = widget.ativo.precoMedio * widget.ativo.tokens;
      final endValue = widget.ativo.valorTotal;
      final variation = endValue - startValue;
      final variationPercent = startValue > 0 ? (variation / startValue) * 100 : 0.0;

      if (!mounted) return;

      setState(() {
        _assetChartData = [startValue, endValue];
        _assetStartValue = startValue;
        _assetEndValue = endValue;
        _assetVariation = variation;
        _assetVariationPercent = variationPercent.isFinite ? variationPercent : 0.0;
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
    final tipoNecessario =
    modo == ModoNegociacao.compra ? TipoOferta.venda : TipoOferta.compra;

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
        ),
      );

      return;
    }

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
                            : _GraficoCard(
                                data: _assetChartData,
                                selectedTimePeriod: selectedTimePeriod,
                                startValue: _assetStartValue,
                                endValue: _assetEndValue,
                                variation: _assetVariation,
                                variationPercent: _assetVariationPercent,
                                startLabel: _assetStartLabel,
                                endLabel: _assetEndLabel,
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
                                  label: 'Resultado no período',
                                  value:
                                  '${_assetVariation >= 0 ? '+' : '-'} R\$ ${_assetVariation.abs().toStringAsFixed(2)}',
                                ),
                                InfoRow(
                                  label: 'Variação no período',
                                  value:
                                  '${_assetVariation >= 0 ? '+' : ''}${_assetVariationPercent.toStringAsFixed(1)}%',
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
            'Acompanhe seus ativos, saldo disponível e movimentações.',
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
  final bool ocultarValores;
  final VoidCallback onToggleOcultarValores;

  const _PatrimonioCard({
    required this.patrimonioTotal,
    required this.saldoDisponivel,
    required this.tokensTotais,
    required this.variacaoMedia,
    required this.onAdicionarFundos,
    required this.ocultarValores,
    required this.onToggleOcultarValores,
  });

  @override
  Widget build(BuildContext context) {
    final positiva = variacaoMedia >= 0;
    final patrimonioTexto = ocultarValores
        ? 'R\$ ••••••'
        : 'R\$ ${patrimonioTotal.toStringAsFixed(2)}';
    final saldoTexto = ocultarValores
        ? 'R\$ ••••••'
        : 'R\$ ${saldoDisponivel.toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: premiumCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: PremiumSectionLabel(text: 'Patrimônio total'),
                ),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onToggleOcultarValores,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: premiumFieldDecoration(
                        radius: 18,
                      ),
                      child: Icon(
                        ocultarValores
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.destaque,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              patrimonioTexto,
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
                    value: saldoTexto,
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
  final List<Map<String, dynamic>> points;
  final String selectedTimePeriod;
  final double startValue;
  final double endValue;
  final double variation;
  final double variationPercent;
  final String startLabel;
  final String endLabel;
  final ValueChanged<String> onPeriodChanged;

  const _GraficoCard({
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
    final variacaoTexto =
        '${positivo ? '+' : '-'} ${_formatMoney(variation.abs())} (${positivo ? '+' : '-'}${variationPercent.abs().toStringAsFixed(1)}%)';
    final middleLabel = _middleLabel();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: premiumFieldDecoration(radius: 14),
                child: Row(
                  children: [
                    Icon(
                      positivo
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: positivo ? AppColors.destaque : const Color(0xFFF87171),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Variação no período',
                        style: const TextStyle(
                          color: AppColors.textoMuitoFraco,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      variacaoTexto,
                      style: TextStyle(
                        color: positivo ? AppColors.destaque : const Color(0xFFF87171),
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
                      painter: LineChartPainter(data: data),
                    )
                  : Center(
                      child: Text(
                        'Ainda não há pontos suficientes para este período. Faça um aporte, compra ou venda para gerar histórico.',
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

class _AtivoCard extends StatelessWidget {
  final AtivoCarteira ativo;
  final VoidCallback onTap;

  const _AtivoCard({
    required this.ativo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                      '${ativo.tokens} tokens • médio R\$ ${ativo.precoMedio.toStringAsFixed(2)}/token',
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
                  const SizedBox(height: 6),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.destaque.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: AppColors.destaque.withOpacity(0.22),
                      ),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.destaque,
                      size: 20,
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
                child: _ResumoItem(
                  label: 'Resultado',
                  value:
                      '${resultadoPositivo ? '+' : '-'} R\$ ${resultadoPeriodo.abs().toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _ResumoItem(
                  label: 'Variação',
                  value:
                      '${resultadoPositivo ? '+' : ''}${variacaoPeriodo.toStringAsFixed(1)}%',
                ),
              ),
              Expanded(
                child: _ResumoItem(
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

class _MovimentacaoTile extends StatelessWidget {
  final String titulo;
  final String descricao;
  final String valor;
  final IconData icon;
  final Color cor;

  const _MovimentacaoTile({
    required this.titulo,
    required this.descricao,
    required this.valor,
    required this.icon,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: premiumCardDecoration(
        radius: 18,
      ),
      child: Row(
        children: [
          IconBox(
            icon: icon,
            size: 36,
            iconSize: 18,
            radius: 12,
            color: cor,
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
              color: cor,
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
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}