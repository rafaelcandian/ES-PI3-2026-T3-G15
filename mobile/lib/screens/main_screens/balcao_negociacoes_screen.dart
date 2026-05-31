/* Guilherme Henrique Moreira - 25006702 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mescla_invest/widgets/shared/section_label.dart';
import 'package:mescla_invest/widgets/shared/app_button.dart';
import 'package:mescla_invest/widgets/shared/page_header.dart';
import 'package:mescla_invest/widgets/app_bar_padrao.dart';
import 'package:mescla_invest/widgets/bottom_nav_bar.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';

import 'package:mescla_invest/services/balcao_service.dart';
import 'package:mescla_invest/services/carteira_service.dart';

import '../../models/balcao_model.dart';
import '../../themes/app_theme.dart';
import '../ordens/ordem_exe_screen.dart';

/* Motor de Exchange P2P (Peer-to-Peer).
   Implementa a lógica de um Limit Order Book (LOB) simplificado, permitindo a descoberta de preços
   e a negociação direta de equity tokenizado entre usuários no mercado secundário. */
class BalcaoDeNegociacoesScreen extends StatefulWidget {
  const BalcaoDeNegociacoesScreen({super.key});

  @override
  State<BalcaoDeNegociacoesScreen> createState() =>
      _BalcaoDeNegociacoesScreenState();
}

class _BalcaoDeNegociacoesScreenState extends State<BalcaoDeNegociacoesScreen>
    with SingleTickerProviderStateMixin {
  ModoNegociacao _modo = ModoNegociacao.compra;
  String _busca = '';

  final TextEditingController _searchController = TextEditingController();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  double _saldo = 0.0;
  List<Oferta> _ofertasCompra = [];
  List<Oferta> _ofertasVenda = [];
  List<AtivoUsuario> _ativosUsuario = [];
  bool _loading = true;

  /* Orquestrador de Dados de Mercado.
     Carrega e segrega as ordens por tipo (Compra/Venda) e origem (Startup/Usuário).
     Implementa a visão híbrida de Mercado Primário (Direct Purchase) e Mercado Secundário (P2P). */
  Future<void> _loadData() async {
    try {
      final saldo = await CarteiraService().getBalance();
      final tokensMap = await CarteiraService().getTokens();

      final startupsSnapshot =
      await FirebaseFirestore.instance.collection('startups').get();

      final List<Oferta> tempOfertasCompra = [];
      final List<Oferta> tempOfertasVenda = [];
      final List<AtivoUsuario> tempAtivosUsuario = [];

      for (final doc in startupsSnapshot.docs) {
        final data = doc.data();
        final startupId = doc.id;
        final title = (data['title'] ?? data['nome'] ?? 'Startup').toString();

        final tokenValue =
        ((data['tokenValue'] ?? data['valorToken'] ?? 1.0) as num)
            .toDouble();

        final minBuyPrice = ((data['minBuyPrice'] ??
            data['tokenValue'] ??
            data['valorToken'] ??
            1.0) as num)
            .toDouble();

        final ticker = (data['ticker'] ?? data['simbolo'] ?? '')
            .toString()
            .trim()
            .toUpperCase();

        final simbolo = ticker.isNotEmpty
            ? ticker
            : title.length >= 3
            ? title.substring(0, 3).toUpperCase()
            : title.toUpperCase();

        final ordens = await BalcaoService().getOpenedOrders(startupId);

        final buyOrders = ordens['buy'] ?? [];
        for (final order in buyOrders) {
          final double variacao = tokenValue > 0
              ? ((order.pricePerToken - tokenValue) / tokenValue) * 100
              : 0.0;

          tempOfertasCompra.add(
            Oferta(
              tipo: TipoOferta.compra,
              quantidade: order.quantity,
              preco: order.pricePerToken,
              empresa: title,
              simbolo: simbolo,
              variacao: variacao,
              volume: '0',
              spread: 0.0,
              startupId: startupId,
              id: order.id,
              userId: order.userId,
              createdAt: order.createdAt,
              minBuyPrice: minBuyPrice,
            ),
          );
        }

        final sellOrders = ordens['sell'] ?? [];
        for (final order in sellOrders) {
          final double variacao = tokenValue > 0
              ? ((order.pricePerToken - tokenValue) / tokenValue) * 100
              : 0.0;

          tempOfertasVenda.add(
            Oferta(
              tipo: TipoOferta.venda,
              quantidade: order.quantity,
              preco: order.pricePerToken,
              empresa: title,
              simbolo: simbolo,
              variacao: variacao,
              volume: '0',
              spread: 0.0,
              startupId: startupId,
              id: order.id,
              userId: order.userId,
              createdAt: order.createdAt,
              minBuyPrice: minBuyPrice,
            ),
          );
        }

        /* Inclui a própria startup como vendedora direta para tokens no mercado primário. */
        final tokensDisponiveis =
            (data['tokens'] as num?)?.toInt() ??
                (data['tokensDisponiveis'] as num?)?.toInt() ??
                (data['quantidadeTokens'] as num?)?.toInt() ??
                0;

        if (tokensDisponiveis > 0) {
          tempOfertasVenda.add(
            Oferta(
              tipo: TipoOferta.venda,
              quantidade: tokensDisponiveis,
              preco: tokenValue,
              empresa: title,
              simbolo: simbolo,
              variacao: 0.0,
              volume: 'Direto',
              spread: 0.0,
              startupId: startupId,
              isStartup: true,
              minBuyPrice: minBuyPrice,
            ),
          );
        }

        if (tokensMap.containsKey(startupId)) {
          final quantidade = (tokensMap[startupId] as num).toInt();

          if (quantidade > 0) {
            tempAtivosUsuario.add(
              AtivoUsuario(
                empresa: title,
                simbolo: simbolo,
                quantidade: quantidade,
                precoMedio: tokenValue,
                startupId: startupId,
                minBuyPrice: minBuyPrice,
                variacao: 0.0,
                volume: '0',
                spread: 0.0,
              ),
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _saldo = saldo;
        _ofertasCompra = tempOfertasCompra;
        _ofertasVenda = tempOfertasVenda;
        _ativosUsuario = tempAtivosUsuario;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados do balcão: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnim = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Curves.easeOut,
    );

    _fadeCtrl.forward();
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /* Alterna entre as visões de compra e venda com feedback tátil e animação. */
  void _trocarModo(ModoNegociacao modo) {
    if (_modo == modo) return;

    HapticFeedback.selectionClick();

    setState(() {
      _modo = modo;
      _busca = '';
      _searchController.clear();
    });

    _fadeCtrl.forward(from: 0);
  }

  /* Algoritmo de Ranking e Priorização de Execução (Matching Engine Logic).
     Aplica as seguintes heurísticas de ordenação:
     1. Ownership: Destaca ordens do usuário atual para gestão de portfólio.
     2. Price Improvement: Melhores preços de venda no topo (Modo Compra) e vice-versa.
     3. Time Priority (FIFO): Ordens mais recentes ganham prioridade em caso de empate de preço. */
  List<Oferta> get _ofertasFiltradas {
    final base =
    _modo == ModoNegociacao.compra ? _ofertasVenda : _ofertasCompra;

    final query = _busca.trim().toLowerCase();

    final filtradas = base.where((oferta) {
      if (query.isEmpty) return true;

      return oferta.empresa.toLowerCase().contains(query) ||
          oferta.simbolo.toLowerCase().contains(query);
    }).toList();

    final uid = FirebaseAuth.instance.currentUser?.uid;

    filtradas.sort((a, b) {
      if (uid != null) {
        final isAUser = a.userId == uid;
        final isBUser = b.userId == uid;

        if (isAUser && !isBUser) return -1;
        if (!isAUser && isBUser) return 1;
      }

      if (_modo == ModoNegociacao.compra) {
        final byPrice = a.preco.compareTo(b.preco);
        if (byPrice != 0) return byPrice;
      } else {
        final byPrice = b.preco.compareTo(a.preco);
        if (byPrice != 0) return byPrice;
      }

      if (a.createdAt != null && b.createdAt != null) {
        return b.createdAt!.compareTo(a.createdAt!);
      }

      return 0;
    });

    return filtradas;
  }

  List<AtivoUsuario> get _ativosFiltrados {
    final query = _busca.trim().toLowerCase();

    if (query.isEmpty) return _ativosUsuario;

    return _ativosUsuario.where((ativo) {
      return ativo.empresa.toLowerCase().contains(query) ||
          ativo.simbolo.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isCompra = _modo == ModoNegociacao.compra;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.fundo,
        extendBody: true,
        appBar: const AppBarPadrao(titulo: ''),
        bottomNavigationBar: const BottomNavBar(selectedIndex: 1),
        body: _loading
            ? const Center(
          child: CircularProgressIndicator(
            color: AppColors.destaque,
          ),
        )
            : Stack(
          children: [
            const _AtmosphericBackground(),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                          child: PageHeader(
                            title: 'Balcão de Tokens',
                            subtitle: 'Compre e venda tokens simulados de startups conectadas ao ecossistema MESCLA.',
                          ),
                        ),
                        _SaldoOperacionalCard(saldo: _saldo),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _TradeControlPanel(
                      controller: _searchController,
                      modo: _modo,
                      onModoChanged: _trocarModo,
                      onSearchChanged: (value) {
                        setState(() {
                          _busca = value;
                        });
                      },
                    ),
                  ),
                  if (!isCompra)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: _AtivosUsuarioCard(
                          ativos: _ativosFiltrados,
                          ofertasDisponiveis: _ofertasCompra,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: SectionLabel(
                        label: isCompra
                            ? 'Melhores ofertas para compra'
                            : 'Melhores ofertas para venda',
                        hint: isCompra
                            ? 'Ordens disponíveis para você comprar tokens.'
                            : 'Ordens disponíveis para você vender seus tokens.',
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 12),
                  ),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: _OfertasList(
                        ofertas: _ofertasFiltradas,
                        modo: _modo,
                        ofertasDisponiveis: _ofertasFiltradas,
                        onRefresh: _loadData,
                      ),
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
}

// ===================== BACKGROUND =====================

class _AtmosphericBackground extends StatelessWidget {
  const _AtmosphericBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.azul.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 210,
            left: -130,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.destaque.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.roxo.withValues(alpha: 0.18),
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

// ===================== SALDO =====================

class _SaldoOperacionalCard extends StatelessWidget {
  final double saldo;

  const _SaldoOperacionalCard({required this.saldo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        decoration: premiumCardDecoration(),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.destaque.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.destaque.withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.destaque,
                size: 21,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SmallLabel(text: 'SALDO DISPONÍVEL'),
                  const SizedBox(height: 6),
                  Text(
                    'R\$ ${saldo.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: AppColors.destaque,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Saldo fictício para ordens simuladas',
                    style: TextStyle(
                      color: AppColors.textoMuitoFraco,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== PAINEL DE CONTROLE =====================

class _TradeControlPanel extends StatelessWidget {
  final TextEditingController controller;
  final ModoNegociacao modo;
  final ValueChanged<ModoNegociacao> onModoChanged;
  final ValueChanged<String> onSearchChanged;

  const _TradeControlPanel({
    required this.controller,
    required this.modo,
    required this.onModoChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hint = modo == ModoNegociacao.compra
        ? 'Buscar startup para comprar...'
        : 'Buscar ativo para vender...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: premiumCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PremiumSectionLabel(text: 'Operação'),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              onChanged: onSearchChanged,
              style: const TextStyle(
                color: AppColors.textoPrincipal,
                fontSize: 14,
              ),
              cursorColor: AppColors.destaque,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textoMuitoFraco,
                  size: 20,
                ),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                  onPressed: () {
                    controller.clear();
                    onSearchChanged('');
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textoMuitoFraco,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _ModeButton(
                  label: 'Comprar',
                  icon: Icons.add_rounded,
                  active: modo == ModoNegociacao.compra,
                  isPrimary: true,
                  onTap: () => onModoChanged(ModoNegociacao.compra),
                ),
                const SizedBox(width: 10),
                _ModeButton(
                  label: 'Vender',
                  icon: Icons.swap_horiz_rounded,
                  active: modo == ModoNegociacao.venda,
                  isPrimary: false,
                  onTap: () => onModoChanged(ModoNegociacao.venda),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeGradient = isPrimary
        ? const LinearGradient(
      colors: [
        AppColors.destaqueClaro,
        AppColors.destaqueEscuro,
      ],
    )
        : const LinearGradient(
      colors: [
        AppColors.azul,
        AppColors.roxo,
      ],
    );

    final textColor = active
        ? isPrimary
        ? AppColors.fundo
        : AppColors.textoPrincipal
        : AppColors.textoSecundario;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 46,
            decoration: BoxDecoration(
              gradient: active ? activeGradient : null,
              color: active ? null : AppColors.campo,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active ? AppColors.bordaDestaque : AppColors.bordaClara,
                width: 0.8,
              ),
              boxShadow: active
                  ? [
                BoxShadow(
                  color: isPrimary
                      ? AppColors.destaque.withValues(alpha: 0.22)
                      : AppColors.azul.withValues(alpha: 0.24),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: textColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== ATIVOS DO USUÁRIO =====================

class _AtivosUsuarioCard extends StatelessWidget {
  final List<AtivoUsuario> ativos;
  final List<Oferta> ofertasDisponiveis;

  const _AtivosUsuarioCard({
    required this.ativos,
    required this.ofertasDisponiveis,
  });

  @override
  Widget build(BuildContext context) {
    if (ativos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 22),
        child: _EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Nenhum ativo encontrado para venda.',
          subtitle:
          'Quando você tiver tokens em carteira, eles aparecerão aqui para criar uma ordem de venda.',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: premiumCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PremiumHeaderEyebrow(text: 'ATIVOS DISPONÍVEIS PARA VENDA'),
            const SizedBox(height: 8),
            const Text(
              'Toque em um ativo para definir quantidade e preço da sua ordem de venda.',
              style: TextStyle(
                color: AppColors.textoMuitoFraco,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            ...ativos.map(
                  (ativo) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AtivoVendaTile(
                  ativo: ativo,
                  ofertasDisponiveis: ofertasDisponiveis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* Atalho para criar uma ordem de venda baseada em um ativo já possuído. */
class _AtivoVendaTile extends StatelessWidget {
  final AtivoUsuario ativo;
  final List<Oferta> ofertasDisponiveis;

  const _AtivoVendaTile({
    required this.ativo,
    required this.ofertasDisponiveis,
  });

  void _abrirVenda(BuildContext context) {
    if (ativo.startupId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível identificar a startup deste ativo.'),
        ),
      );
      return;
    }

    final ofertaVenda = Oferta(
      tipo: TipoOferta.venda,
      quantidade: ativo.quantidade,
      preco: ativo.precoMedio,
      empresa: ativo.empresa,
      simbolo: ativo.simbolo,
      variacao: ativo.variacao,
      volume: ativo.volume,
      spread: ativo.spread,
      startupId: ativo.startupId,
      isStartup: false,
      minBuyPrice: ativo.minBuyPrice,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrdemExeScreen(
          oferta: ofertaVenda,
          modo: ModoNegociacao.venda,
          ofertasDisponiveis: ofertasDisponiveis,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valorEstimado = ativo.quantidade * ativo.precoMedio;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _abrirVenda(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: premiumFieldDecoration(
            radius: 18,
          ),
          child: Row(
            children: [
              _TickerBox(
                simbolo: ativo.simbolo,
                color: AppColors.azul,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ativo.empresa,
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
                      '${ativo.quantidade} tokens disponíveis',
                      style: const TextStyle(
                        color: AppColors.textoFraco,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Criar ordem de venda',
                      style: TextStyle(
                        color: AppColors.azul,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Valor estimado',
                    style: TextStyle(
                      color: AppColors.textoMuitoFraco,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${valorEstimado.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.destaque,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textoMuitoFraco,
                    size: 20,
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

// ===================== LISTA DE OFERTAS =====================

class _OfertasList extends StatelessWidget {
  final List<Oferta> ofertas;
  final ModoNegociacao modo;
  final List<Oferta> ofertasDisponiveis;
  final Future<void> Function()? onRefresh;

  const _OfertasList({
    required this.ofertas,
    required this.modo,
    required this.ofertasDisponiveis,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (ofertas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        child: _EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Nenhuma startup encontrada.',
          subtitle: 'Tente buscar por outro nome ou ticker.',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: ofertas.asMap().entries.map((entry) {
          final index = entry.key;
          final oferta = entry.value;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == ofertas.length - 1 ? 0 : 12,
            ),
            child: _OfertaCard(
              oferta: oferta,
              modo: modo,
              position: index + 1,
              ofertasDisponiveis: ofertasDisponiveis,
              onRefresh: onRefresh,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OfertaCard extends StatefulWidget {
  final Oferta oferta;
  final ModoNegociacao modo;
  final int position;
  final List<Oferta> ofertasDisponiveis;
  final Future<void> Function()? onRefresh;

  const _OfertaCard({
    required this.oferta,
    required this.modo,
    required this.position,
    required this.ofertasDisponiveis,
    this.onRefresh,
  });

  @override
  State<_OfertaCard> createState() => _OfertaCardState();
}

class _OfertaCardState extends State<_OfertaCard> {
  bool _pressed = false;

  /* Permite ao usuário remover sua própria ordem do balcão via Cloud Function. */
  Future<void> _cancelarOferta(BuildContext context) async {
    if (widget.oferta.id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível identificar esta oferta.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text(
            'Cancelar oferta',
            style: TextStyle(
              color: AppColors.destaque,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Tem certeza que deseja cancelar esta oferta?',
            style: TextStyle(
              color: AppColors.textoFraco,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Não',
                style: TextStyle(
                  color: AppColors.textoFraco,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Sim',
                style: TextStyle(
                  color: AppColors.destaque,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final result = await BalcaoService().cancelarOferta(
      orderId: widget.oferta.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == null ? 'Oferta cancelada com sucesso.' : result,
        ),
      ),
    );

    if (result == null) {
      await widget.onRefresh?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompra = widget.modo == ModoNegociacao.compra;
    final accent = isCompra ? AppColors.destaque : AppColors.azul;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = widget.oferta.userId == uid;

    final variationColor = widget.oferta.variacao >= 0
        ? AppColors.destaque
        : AppColors.textoFraco;

    return GestureDetector(
      onTapDown: (_) {
        if (!isOwner) {
          setState(() => _pressed = true);
        }
      },
      onTapUp: (_) {
        if (isOwner) return;

        setState(() => _pressed = false);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrdemExeScreen(
              oferta: widget.oferta,
              modo: widget.modo,
              ofertasDisponiveis: widget.ofertasDisponiveis,
              compraDireto: widget.oferta.isStartup,
            ),
          ),
        );
      },
      onTapCancel: () {
        if (!isOwner) {
          setState(() => _pressed = false);
        }
      },
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: premiumCardDecoration(
                radius: 22,
              ),
              child: Row(
                children: [
                  _TickerBox(
                    simbolo: widget.oferta.simbolo,
                    color: accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Badge(
                              label: isCompra ? 'VENDA' : 'COMPRA',
                              color: accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '#${widget.position}',
                              style: const TextStyle(
                                color: AppColors.textoMuitoFraco,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          widget.oferta.empresa,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textoPrincipal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            _MiniInfo(
                              label: 'Tokens',
                              value: '${widget.oferta.quantidade}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'R\$ ${widget.oferta.preco.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.destaque,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            widget.oferta.variacao >= 0
                                ? Icons.north_east_rounded
                                : Icons.south_east_rounded,
                            color: variationColor,
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${widget.oferta.variacao >= 0 ? '+' : ''}${widget.oferta.variacao.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: variationColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      isOwner
                          ? IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _cancelarOferta(context),
                        tooltip: 'Cancelar oferta',
                      )
                          : AppButton.primary(
                        label: isCompra ? 'Comprar' : 'Vender',
                        fullWidth: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrdemExeScreen(
                                oferta: widget.oferta,
                                modo: widget.modo,
                                ofertasDisponiveis: widget.ofertasDisponiveis,
                                compraDireto: widget.oferta.isStartup,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 16,
              bottom: 16,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== COMPONENTES PEQUENOS =====================

class _TickerBox extends StatelessWidget {
  final String simbolo;
  final Color color;

  const _TickerBox({
    required this.simbolo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
        ),
      ),
      child: Center(
        child: Text(
          simbolo,
          style: TextStyle(
            fontSize: simbolo.length > 3 ? 9 : 12,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _SmallLabel extends StatelessWidget {
  final String text;

  const _SmallLabel({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        color: AppColors.textoMuitoFraco,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;

  const _MiniInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 26,
      ),
      decoration: premiumCardDecoration(
        radius: 22,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.textoMuitoFraco,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textoFraco,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
