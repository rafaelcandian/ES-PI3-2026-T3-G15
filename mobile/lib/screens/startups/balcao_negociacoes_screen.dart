import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mescla_invest/widgets/bottom_nav_bar.dart';
import 'package:mescla_invest/widgets/app_bar_padrao.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';

import '../../models/balcao_model.dart';
import '../../themes/app_theme.dart';
import '../ordens/ordem_exe_screen.dart';

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

  final List<Oferta> _ofertasCompra = const [
    Oferta(
      tipo: TipoOferta.compra,
      quantidade: 100,
      preco: 25.50,
      empresa: 'NeuroPulse AI',
      simbolo: 'NPA',
      variacao: 3.2,
      volume: '2.8k',
      spread: 0.7,
    ),
    Oferta(
      tipo: TipoOferta.compra,
      quantidade: 200,
      preco: 24.50,
      empresa: 'QuantLedger',
      simbolo: 'QLG',
      variacao: -1.4,
      volume: '1.4k',
      spread: 1.1,
    ),
    Oferta(
      tipo: TipoOferta.compra,
      quantidade: 350,
      preco: 22.00,
      empresa: 'SolarGrid',
      simbolo: 'SLG',
      variacao: 5.8,
      volume: '3.6k',
      spread: 0.5,
    ),
  ];

  final List<Oferta> _ofertasVenda = const [
    Oferta(
      tipo: TipoOferta.venda,
      quantidade: 50,
      preco: 26.00,
      empresa: 'NeuroPulse AI',
      simbolo: 'NPA',
      variacao: 2.1,
      volume: '1.9k',
      spread: 0.9,
    ),
    Oferta(
      tipo: TipoOferta.venda,
      quantidade: 150,
      preco: 27.00,
      empresa: 'QuantLedger',
      simbolo: 'QLG',
      variacao: -0.8,
      volume: '950',
      spread: 1.4,
    ),
    Oferta(
      tipo: TipoOferta.venda,
      quantidade: 80,
      preco: 29.50,
      empresa: 'BioSync',
      simbolo: 'BIO',
      variacao: 7.3,
      volume: '4.2k',
      spread: 0.6,
    ),
  ];

  final List<AtivoUsuario> _ativosUsuario = const [
    AtivoUsuario(
      empresa: 'NeuroPulse AI',
      simbolo: 'NPA',
      quantidade: 120,
      precoMedio: 22.40,
    ),
    AtivoUsuario(
      empresa: 'BioSync',
      simbolo: 'BIO',
      quantidade: 80,
      precoMedio: 26.10,
    ),
    AtivoUsuario(
      empresa: 'QuantLedger',
      simbolo: 'QLG',
      quantidade: 45,
      precoMedio: 23.70,
    ),
  ];

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
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

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

  List<Oferta> get _ofertasFiltradas {
    final base =
    _modo == ModoNegociacao.compra ? _ofertasVenda : _ofertasCompra;

    final query = _busca.trim().toLowerCase();

    final filtradas = base.where((oferta) {
      if (query.isEmpty) return true;

      return oferta.empresa.toLowerCase().contains(query) ||
          oferta.simbolo.toLowerCase().contains(query);
    }).toList();

    filtradas.sort((a, b) {
      if (_modo == ModoNegociacao.compra) {
        return a.preco.compareTo(b.preco);
      }

      return b.preco.compareTo(a.preco);
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
        appBar: const AppBarPadrao(titulo: 'Balcão de Tokens'),
        bottomNavigationBar: const BottomNavBar(selectedIndex: 1),
        body: Stack(
          children: [
            const _AtmosphericBackground(),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _PageHeader(),
                        SizedBox(height: 20),
                        _SaldoOperacionalCard(),
                        SizedBox(height: 18),
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
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: _SectionLabel(
                        label: isCompra
                            ? 'MELHORES OFERTAS PARA COMPRA'
                            : 'MELHORES OFERTAS PARA VENDA',
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
                    AppColors.azul.withOpacity(0.22),
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
                    AppColors.destaque.withOpacity(0.07),
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
                    AppColors.roxo.withOpacity(0.18),
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

// ===================== HEADER =====================

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 14),
          PremiumHeaderEyebrow(text: 'MERCADO SECUNDÁRIO'),
          SizedBox(height: 14),
          Text(
            'Compre e venda tokens simulados de startups conectadas ao ecossistema MESCLA.',
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

// ===================== SALDO =====================

class _SaldoOperacionalCard extends StatelessWidget {
  const _SaldoOperacionalCard();

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
                color: AppColors.destaque.withOpacity(0.12),
                border: Border.all(
                  color: AppColors.destaque.withOpacity(0.28),
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SmallLabel(text: 'SALDO DISPONÍVEL'),
                  SizedBox(height: 6),
                  Text(
                    'R\$ 12.750,00',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: AppColors.destaque,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
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
                      ? AppColors.destaque.withOpacity(0.22)
                      : AppColors.azul.withOpacity(0.24),
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

  const _AtivosUsuarioCard({
    required this.ativos,
  });

  @override
  Widget build(BuildContext context) {
    if (ativos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 22),
        child: _EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Nenhum ativo encontrado para venda.',
          subtitle: 'Tente buscar por outro nome ou ticker.',
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
            const SizedBox(height: 14),
            ...ativos.map(
                  (ativo) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AtivoVendaTile(ativo: ativo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtivoVendaTile extends StatelessWidget {
  final AtivoUsuario ativo;

  const _AtivoVendaTile({
    required this.ativo,
  });

  @override
  Widget build(BuildContext context) {
    final valorEstimado = ativo.quantidade * ativo.precoMedio;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: premiumFieldDecoration(
        radius: 18,
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
            ],
          ),
        ],
      ),
    );
  }
}

// ===================== LABEL DE SEÇÃO =====================

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
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: const TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== LISTA DE OFERTAS =====================

class _OfertasList extends StatelessWidget {
  final List<Oferta> ofertas;
  final ModoNegociacao modo;
  final List<Oferta> ofertasDisponiveis;

  const _OfertasList({
    required this.ofertas,
    required this.modo,
    required this.ofertasDisponiveis,
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

  const _OfertaCard({
    required this.oferta,
    required this.modo,
    required this.position,
    required this.ofertasDisponiveis,
  });

  @override
  State<_OfertaCard> createState() => _OfertaCardState();
}

class _OfertaCardState extends State<_OfertaCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isCompra = widget.modo == ModoNegociacao.compra;
    final accent = isCompra ? AppColors.destaque : AppColors.azul;

    final variationColor = widget.oferta.variacao >= 0
        ? AppColors.destaque
        : AppColors.textoFraco;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrdemExeScreen(
              oferta: widget.oferta,
              modo: widget.modo,
              ofertasDisponiveis: widget.ofertasDisponiveis,
            ),
          ),
        );
      },
      onTapCancel: () {
        setState(() => _pressed = false);
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
                              label: 'Vol',
                              value: widget.oferta.volume,
                            ),
                            _MiniInfo(
                              label: 'Spread',
                              value:
                              '${widget.oferta.spread.toStringAsFixed(1)}%',
                            ),
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
                      Container(
                        width: 86,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: isCompra
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
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            isCompra ? 'COMPRAR' : 'VENDER',
                            style: TextStyle(
                              color: isCompra
                                  ? AppColors.fundo
                                  : AppColors.textoPrincipal,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.30),
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
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.35),
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
            style: const TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 10,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppColors.textoFraco,
              fontSize: 10,
              fontWeight: FontWeight.w800,
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