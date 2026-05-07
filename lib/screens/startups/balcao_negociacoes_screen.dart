import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mescla_invest/widgets/bottom_nav_bar.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF020818);
  static const surface = Color(0xFF0B1230);
  static const surfaceUp = Color(0xFF0F1840);
  static const surfaceRaised = Color(0xFF0F1840);
  static const card = Color(0xFF0D1535);

  static const gold = Color(0xFFEFCD57);
  static const goldSoft = Color(0xFFFFE680);
  static const goldDim = Color(0xFFB89A2E);
  static const goldGlow = Color(0x22EFCD57);
  static const goldBorder = Color(0x33EFCD57);

  static const roxo = Color(0xFF6F38C5);
  static const azul = Color(0xFF2148C6);
  static const blue = Color(0xFF1A3A8F);

  static const white = Colors.white;
  static const white70 = Colors.white70;
  static const white50 = Color(0x80FFFFFF);
  static const white30 = Color(0x4DFFFFFF);
  static const white12 = Color(0x1FFFFFFF);
  static const white06 = Color(0x0FFFFFFF);
}

enum ModoNegociacao { compra, venda }

enum TipoOferta { compra, venda }

class Oferta {
  final TipoOferta tipo;
  final int quantidade;
  final double preco;
  final String empresa;
  final String simbolo;
  final double variacao;
  final String volume;
  final double spread;

  const Oferta({
    required this.tipo,
    required this.quantidade,
    required this.preco,
    required this.empresa,
    required this.simbolo,
    required this.variacao,
    required this.volume,
    required this.spread,
  });
}

class AtivoUsuario {
  final String empresa;
  final String simbolo;
  final int quantidade;

  const AtivoUsuario({
    required this.empresa,
    required this.simbolo,
    required this.quantidade,
  });
}

class BalcaoDeNegociacoesScreen extends StatefulWidget {
  const BalcaoDeNegociacoesScreen({super.key});

  @override
  State<BalcaoDeNegociacoesScreen> createState() =>
      _BalcaoDeNegociacoesScreenState();
}

class _BalcaoDeNegociacoesScreenState extends State<BalcaoDeNegociacoesScreen>
    with TickerProviderStateMixin {
  ModoNegociacao _modo = ModoNegociacao.compra;
  String _busca = '';

  final TextEditingController _searchController = TextEditingController();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

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
    ),
    AtivoUsuario(
      empresa: 'BioSync',
      simbolo: 'BIO',
      quantidade: 80,
    ),
    AtivoUsuario(
      empresa: 'QuantLedger',
      simbolo: 'QLG',
      quantidade: 45,
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

    setState(() => _modo = modo);
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

  @override
  Widget build(BuildContext context) {
    final isCompra = _modo == ModoNegociacao.compra;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Stack(
          children: [
            const _AtmosphericBackground(),

            Column(
              children: [
                const _TopBar(),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),

                        const _PageHeader(),

                        const SizedBox(height: 18),

                        const _SaldoOperacionalCard(),

                        const SizedBox(height: 18),

                        _TradeControlPanel(
                          controller: _searchController,
                          modo: _modo,
                          onModoChanged: _trocarModo,
                          onSearchChanged: (value) {
                            setState(() => _busca = value);
                          },
                        ),

                        if (!isCompra) ...[
                          const SizedBox(height: 18),
                          _AtivosUsuarioCard(ativos: _ativosUsuario),
                        ],

                        const SizedBox(height: 22),

                        _SectionLabel(
                          label: isCompra
                              ? 'MELHORES OFERTAS PARA COMPRA'
                              : 'MELHORES OFERTAS PARA VENDA',
                          hint: isCompra
                              ? 'Ordenado do menor para o maior preço'
                              : 'Ordenado do maior para o menor preço',
                        ),

                        const SizedBox(height: 12),

                        FadeTransition(
                          opacity: _fadeAnim,
                          child: _OfertasList(
                            ofertas: _ofertasFiltradas,
                            modo: _modo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const BottomNavBar(selectedIndex: 1),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Background ───────────────────────────────────────────────────────────────
class _AtmosphericBackground extends StatelessWidget {
  const _AtmosphericBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -80,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _C.gold.withOpacity(0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 160,
            left: -130,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _C.roxo.withOpacity(0.24),
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

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: _C.surface.withOpacity(0.92),
        border: const Border(
          bottom: BorderSide(
            color: _C.white06,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_C.roxo, _C.azul],
              ),
              border: Border.all(
                color: _C.gold.withOpacity(0.45),
                width: 0.8,
              ),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: _C.white,
              size: 18,
            ),
          ),

          const SizedBox(width: 12),

          const Text(
            'MESCLAINVEST',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: _C.gold,
              letterSpacing: 2.7,
            ),
          ),

          const Spacer(),

          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _C.white06,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _C.white12,
                width: 0.7,
              ),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: _C.gold,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balcão',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: _C.white,
              height: 1,
              letterSpacing: -0.4,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Negocie tokens simulados de startups do ecossistema Mescla.',
            style: TextStyle(
              fontSize: 14,
              color: _C.white50,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Saldo Operacional ────────────────────────────────────────────────────────
class _SaldoOperacionalCard extends StatelessWidget {
  const _SaldoOperacionalCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _C.white12,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: _C.gold.withOpacity(0.08),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SmallLabel(text: 'SALDO DISPONÍVEL'),
                  SizedBox(height: 8),
                  Text(
                    'R\$ 12.750,00',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: _C.gold,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Saldo fictício para ordens simuladas',
                    style: TextStyle(
                      color: _C.white30,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              width: 96,
              height: 60,
              child: CustomPaint(
                painter: _MiniChartPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search + Mode Controls ───────────────────────────────────────────────────
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.surface.withOpacity(0.88),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _C.white06,
            width: 0.6,
          ),
        ),
        child: Column(
          children: [
            TextField(
              controller: controller,
              onChanged: onSearchChanged,
              style: const TextStyle(
                color: _C.white,
                fontSize: 14,
              ),
              cursorColor: _C.gold,
              decoration: InputDecoration(
                hintText: 'Buscar startup ou ticker...',
                hintStyle: const TextStyle(
                  color: _C.white30,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _C.white30,
                  size: 20,
                ),
                filled: true,
                fillColor: _C.white06,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _C.white06,
                    width: 0.6,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _C.gold.withOpacity(0.55),
                    width: 0.8,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _ModeButton(
                  label: 'Comprar tokens',
                  icon: Icons.add_rounded,
                  active: modo == ModoNegociacao.compra,
                  activeColor: _C.gold,
                  onTap: () => onModoChanged(ModoNegociacao.compra),
                ),

                const SizedBox(width: 8),

                _ModeButton(
                  label: 'Vender tokens',
                  icon: Icons.swap_horiz_rounded,
                  active: modo == ModoNegociacao.venda,
                  activeColor: _C.azul,
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
  final Color activeColor;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = active
        ? activeColor == _C.gold
        ? _C.surface
        : _C.white
        : _C.white50;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 44,
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
              colors: activeColor == _C.gold
                  ? [_C.gold, _C.goldSoft]
                  : [_C.azul, _C.roxo],
            )
                : null,
            color: active ? null : _C.white06,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? activeColor.withOpacity(0.55)
                  : _C.white06,
              width: 0.7,
            ),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── User Assets ──────────────────────────────────────────────────────────────
class _AtivosUsuarioCard extends StatelessWidget {
  final List<AtivoUsuario> ativos;

  const _AtivosUsuarioCard({required this.ativos});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.surface.withOpacity(0.82),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _C.azul.withOpacity(0.25),
            width: 0.7,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SmallLabel(text: 'SEUS ATIVOS DISPONÍVEIS PARA VENDA'),

            const SizedBox(height: 12),

            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ativos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  final ativo = ativos[index];

                  return Container(
                    width: 128,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _C.white06,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _C.white06,
                        width: 0.6,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ativo.simbolo,
                          style: const TextStyle(
                            color: _C.gold,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${ativo.quantidade} tokens',
                          style: const TextStyle(
                            color: _C.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          ativo.empresa,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _C.white30,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: _C.white30,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 0.5,
                  color: _C.white06,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: const TextStyle(
              color: _C.white30,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Offers List ──────────────────────────────────────────────────────────────
class _OfertasList extends StatelessWidget {
  final List<Oferta> ofertas;
  final ModoNegociacao modo;

  const _OfertasList({
    required this.ofertas,
    required this.modo,
  });

  @override
  Widget build(BuildContext context) {
    if (ofertas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Center(
          child: Text(
            'Nenhuma startup encontrada.',
            style: TextStyle(
              color: _C.white30,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: ofertas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _OfertaCard(
        oferta: ofertas[i],
        modo: modo,
        position: i + 1,
      ),
    );
  }
}

class _OfertaCard extends StatefulWidget {
  final Oferta oferta;
  final ModoNegociacao modo;
  final int position;

  const _OfertaCard({
    required this.oferta,
    required this.modo,
    required this.position,
  });

  @override
  State<_OfertaCard> createState() => _OfertaCardState();
}

class _OfertaCardState extends State<_OfertaCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isCompra = widget.modo == ModoNegociacao.compra;
    final accent = isCompra ? _C.gold : _C.azul;
    final variationColor =
    widget.oferta.variacao >= 0 ? _C.gold : _C.white50;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);

        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => _TradeModal(
            oferta: widget.oferta,
            modo: widget.modo,
          ),
        );
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _C.card.withOpacity(0.95),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _C.white06,
                  width: 0.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accent.withOpacity(0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.oferta.simbolo,
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize:
                          widget.oferta.simbolo.length > 3 ? 9 : 11,
                          fontWeight: FontWeight.w900,
                          color: accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Badge(
                              label: isCompra ? 'ASK' : 'BID',
                              color: accent,
                              darkText: isCompra,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '#${widget.position}',
                              style: const TextStyle(
                                color: _C.white30,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          widget.oferta.empresa,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: _C.white,
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
                          fontFamily: 'Syne',
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: _C.gold,
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
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Container(
                        width: 92,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCompra
                                ? [_C.gold, _C.goldSoft]
                                : [_C.azul, _C.roxo],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            isCompra ? 'COMPRAR' : 'VENDER',
                            style: TextStyle(
                              color: isCompra ? _C.surface : _C.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 0.8,
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
              top: 14,
              bottom: 14,
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

// ─── Modal ────────────────────────────────────────────────────────────────────
class _TradeModal extends StatelessWidget {
  final Oferta oferta;
  final ModoNegociacao modo;

  const _TradeModal({
    required this.oferta,
    required this.modo,
  });

  @override
  Widget build(BuildContext context) {
    final isCompra = modo == ModoNegociacao.compra;
    final accent = isCompra ? _C.gold : _C.azul;
    final total = oferta.preco * oferta.quantidade;
    final taxa = total * 0.004;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: _C.white12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withOpacity(0.35),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Text(
                    oferta.simbolo,
                    style: TextStyle(
                      color: accent,
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
                      oferta.empresa,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _C.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompra
                          ? 'Você está prestes a comprar tokens'
                          : 'Você está prestes a vender tokens',
                      style: const TextStyle(
                        color: _C.white30,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TradeInfo(
                label: 'PREÇO',
                value: 'R\$ ${oferta.preco.toStringAsFixed(2)}',
              ),
              _TradeInfo(
                label: 'TOKENS',
                value: '${oferta.quantidade}',
              ),
              _TradeInfo(
                label: 'SPREAD',
                value: '${oferta.spread.toStringAsFixed(1)}%',
              ),
            ],
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _C.white06,
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                _TradeSummaryRow(
                  label: 'Subtotal',
                  value: 'R\$ ${total.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 12),
                _TradeSummaryRow(
                  label: 'Taxa simulada',
                  value: 'R\$ ${taxa.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 12),
                const _TradeSummaryRow(
                  label: 'Liquidação',
                  value: 'Instantânea',
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isCompra
                          ? 'Compra simulada executada com sucesso.'
                          : 'Venda simulada executada com sucesso.',
                    ),
                    backgroundColor: _C.surfaceUp,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(
                isCompra ? 'EXECUTAR COMPRA' : 'EXECUTAR VENDA',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 1,
                  color: isCompra ? _C.surface : _C.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small Components ─────────────────────────────────────────────────────────
class _SmallLabel extends StatelessWidget {
  final String text;

  const _SmallLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        color: _C.white50,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool darkText;

  const _Badge({
    required this.label,
    required this.color,
    this.darkText = false,
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
              color: _C.white30,
              fontSize: 10,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: _C.white50,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeInfo extends StatelessWidget {
  final String label;
  final String value;

  const _TradeInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _C.white30,
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: _C.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _TradeSummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _TradeSummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _C.white50,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _C.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _C.white06
      ..strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [_C.gold, _C.goldSoft],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    for (int i = 0; i < 18; i++) {
      final x = size.width * (i / 17);
      final raw = math.sin(i * 0.75) * 0.24 + math.cos(i * 0.38) * 0.12;
      final y = size.height * (0.55 - raw);

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