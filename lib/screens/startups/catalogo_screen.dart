import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mescla_invest/screens/startups/startup_data.dart';
import 'package:mescla_invest/widgets/bottom_nav_bar.dart';
import 'package:mescla_invest/screens/startups/startup_card.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────────
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

// ─── Screen ────────────────────────────────────────────────────────────────────
class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen>
    with TickerProviderStateMixin {

  String _stage = 'Todas';
  String _area  = 'Todas';
  double _walletBalance = 0.0;

  late AnimationController _heroAnim;
  late Animation<double>   _heroFade;
  late Animation<Offset>   _heroSlide;

  late AnimationController _pulseAnim;
  late Animation<double>   _pulse;

  final _startupsRef = FirebaseFirestore.instance.collection('startups');
  final _usersRef    = FirebaseFirestore.instance.collection('users');

  final List<String> _stages = ['Todas', 'Nova', 'Operação', 'Expansão'];
  final List<String> _areas  = [
    'Todas', 'Tecnologia', 'Educação', 'Saúde', 'Financeiro', 'Agronegócio'
  ];

  // ─── Init / Dispose ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _getWalletBalance();

    _heroAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _heroFade = CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, -0.12), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut));
    _heroAnim.forward();

    _pulseAnim = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.82, end: 1.0).animate(
        CurvedAnimation(parent: _pulseAnim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  // ─── Data ────────────────────────────────────────────────────────────────────
  Future<void> _getWalletBalance() async {
    try {
      const userId = 'user123'; // substitua por FirebaseAuth.instance.currentUser?.uid
      final doc = await _usersRef.doc(userId).get();
      if (doc.exists && mounted) {
        setState(() => _walletBalance = (doc['walletBalance'] ?? 0.0).toDouble());
      }
    } catch (e) {
      debugPrint('Erro ao obter saldo: $e');
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        extendBody: true,
        bottomNavigationBar: const BottomNavBar(selectedIndex: 0),
        body: Stack(children: [
          _AtmosphericBg(),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero header (topbar + title + wallet + filters)
                FadeTransition(
                  opacity: _heroFade,
                  child: SlideTransition(
                    position: _heroSlide,
                    child: _HeroHeader(
                      walletBalance: _walletBalance,
                      stages: _stages,
                      selectedStage: _stage,
                      onStageSelected: (v) => setState(() => _stage = v),
                      pulseAnim: _pulse,
                    ),
                  ),
                ),
                // ── List
                Expanded(child: _buildList()),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Startup List ─────────────────────────────────────────────────────────────
  Widget _buildList() {
    Query query = _startupsRef;
    if (_stage != 'Todas') query = query.where('stage', isEqualTo: _stage);
    if (_area  != 'Todas') query = query.where('area',  isEqualTo: _area);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _C.gold, strokeWidth: 1.5),
          );
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.search_off_rounded, color: _C.white30, size: 48),
              const SizedBox(height: 12),
              const Text('Nenhuma startup encontrada.',
                  style: TextStyle(color: _C.white30, fontSize: 14)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = StartupData.fromFirestore(docs[i]);
            return StartupCard(data: data);
          },
        );
      },
    );
  }
}

// ─── Atmospheric Background ───────────────────────────────────────────────────
class _AtmosphericBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(children: [
        Positioned(
          top: -140, right: -90,
          child: Container(
            width: 360, height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF1A3A8F).withOpacity(0.28),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          top: 100, left: -60,
          child: Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _C.gold.withOpacity(0.06),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 80, right: -80,
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _C.blue.withOpacity(0.15),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final double walletBalance;
  final List<String> stages;
  final String selectedStage;
  final ValueChanged<String> onStageSelected;
  final Animation<double> pulseAnim;

  const _HeroHeader({
    required this.walletBalance,
    required this.stages,
    required this.selectedStage,
    required this.onStageSelected,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _TopBar(pulseAnim: pulseAnim),
      const SizedBox(height: 24),
      _TitleBlock(),
      const SizedBox(height: 20),
      _WalletCard(balance: walletBalance),
      const SizedBox(height: 20),
      _StageFilterRow(stages: stages, selected: selectedStage, onSelect: onStageSelected),
      const SizedBox(height: 8),
    ]);
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _TopBar({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Row(children: [
        // Avatar
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _C.goldBorder, width: 1.5),
            gradient: const LinearGradient(
              colors: [Color(0xFF162248), Color(0xFF0B1230)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipOval(
            child: Image.network(
              'https://via.placeholder.com/80',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.person_rounded, color: _C.gold, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Logo
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('MESCLAINVEST',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _C.gold,
              letterSpacing: 2.5,
            ),
          ),
          const Text('Bem-vindo de volta',
            style: TextStyle(fontSize: 11, color: _C.white30, letterSpacing: 0.3),
          ),
        ]),
        const Spacer(),
        // Notification bell
        ScaleTransition(
          scale: pulseAnim,
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _C.goldGlow,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _C.goldBorder, width: 0.8),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: _C.gold, size: 20,
              ),
            ),
            Positioned(
              top: -3, right: -3,
              child: Container(
                width: 9, height: 9,
                decoration: const BoxDecoration(
                  color: _C.gold,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Title Block ──────────────────────────────────────────────────────────────
class _TitleBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Eyebrow label
        Row(children: [
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(
              color: _C.gold,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _C.gold.withOpacity(0.8), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 8),
          const Text('OPORTUNIDADES DE INVESTIMENTO',
            style: TextStyle(
              fontSize: 9,
              color: _C.white30,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        // Main title
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Colors.white, Color(0xFFBBCCFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(b),
          child: const Text('Catálogo de\nStartups',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Oportunidades exclusivas de investimento em\nequity através de ativos digitais fracionados.',
          style: TextStyle(
            fontSize: 13,
            color: _C.white50,
            height: 1.5,
          ),
        ),
      ]),
    );
  }
}

// ─── Wallet Card ──────────────────────────────────────────────────────────────
class _WalletCard extends StatelessWidget {
  final double balance;
  const _WalletCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F1840), Color(0xFF162350)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.goldBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: _C.gold.withOpacity(0.07),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(children: [
          // Icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.goldGlow,
              border: Border.all(color: _C.goldBorder, width: 0.8),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: _C.gold, size: 20),
          ),
          const SizedBox(width: 14),
          // Label + balance
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('SALDO DA CARTEIRA',
                style: TextStyle(
                  fontSize: 9,
                  color: _C.white30,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [_C.gold, Color(0xFFFAE08A)],
                ).createShader(b),
                child: Text(
                  'R\$ ${balance.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ]),
          ),
          // Invest button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_C.goldDim, _C.gold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text('Investir',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B1230),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Stage Filter Row ─────────────────────────────────────────────────────────
class _StageFilterRow extends StatelessWidget {
  final List<String> stages;
  final String selected;
  final ValueChanged<String> onSelect;

  const _StageFilterRow({
    required this.stages,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        itemCount: stages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final label = stages[i];
          final active = label == selected;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(label);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
              decoration: BoxDecoration(
                color: active ? _C.gold : _C.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: active ? _C.gold : _C.white12,
                  width: 0.8,
                ),
                boxShadow: active
                    ? [BoxShadow(
                  color: _C.gold.withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                )]
                    : [],
              ),
              child: Center(
                child: Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? const Color(0xFF0B1230) : _C.white50,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}