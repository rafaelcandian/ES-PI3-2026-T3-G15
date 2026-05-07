import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Animações ──────────────────────────────────────────────────────────────
  late AnimationController _logoCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _contentCtrl;
  late AnimationController _barCtrl;

  late Animation<double>  _logoScale;
  late Animation<double>  _logoFade;
  late Animation<double>  _pulse;
  late Animation<double>  _contentFade;
  late Animation<Offset>  _contentSlide;
  late Animation<double>  _barProgress;

  // ── Cores inline (sem depender de AppColors para tokens internos) ──────────
  static const _bg          = Color(0xFF0D1117);
  static const _surface     = Color(0xFF0F1440);
  static const _gold        = Color(0xFFEFAD1A);
  static const _goldDim     = Color(0xFFB88A10);
  static const _goldGlow    = Color(0x22EFAD1A);
  static const _goldBorder  = Color(0x44EFAD1A);
  static const _white30     = Color(0x4DFFFFFF);
  static const _white10     = Color(0x1AFFFFFF);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    // 1. Logo entra com scale + fade (0–600ms)
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);

    // 2. Anel de glow pulsa continuamente
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // 3. Textos e tagline sobem com fade (400ms delay)
    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _contentFade = CurvedAnimation(
        parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.18), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));

    // 4. Barra de progresso linear (0 → 1 em 1800ms)
    _barCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _barProgress = CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut);

    // Sequência de entrada
    _logoCtrl.forward().then((_) {
      _contentCtrl.forward();
      _barCtrl.forward();
    });

    _checkUser();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    _contentCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  // ── Navegação ──────────────────────────────────────────────────────────────
  Future<void> _checkUser() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    Navigator.pushReplacementNamed(
      context,
      user != null ? '/catalogo' : '/login',
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(children: [

          // ── Atmospheric glows
          _buildGlows(size),

          // ── Conteúdo central
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // Anel de glow + ícone
                _buildLogoRing(),
                const SizedBox(height: 32),

                // Nome + tagline
                FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: _buildBrandText(),
                  ),
                ),
                const SizedBox(height: 52),

                // Barra de progresso
                FadeTransition(
                  opacity: _contentFade,
                  child: _buildProgressBar(),
                ),
              ],
            ),
          ),

          // ── Rodapé
          Positioned(
            bottom: 36, left: 0, right: 0,
            child: FadeTransition(
              opacity: _contentFade,
              child: const Text(
                '© 2024 MESCLAINVEST  •  ACADEMIC & FINANCIAL EXCELLENCE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: _white30,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Logo ring ──────────────────────────────────────────────────────────────
  Widget _buildLogoRing() {
    return ScaleTransition(
      scale: _logoScale,
      child: FadeTransition(
        opacity: _logoFade,
        child: ScaleTransition(
          scale: _pulse,
          child: Stack(alignment: Alignment.center, children: [

            // Anel externo difuso
            Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _gold.withOpacity(0.18),
                  Colors.transparent,
                ]),
              ),
            ),

            // Anel com borda
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _goldGlow,
                border: Border.all(color: _goldBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(0.22),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),

            // Logo asset — se não existir, usa ícone fallback
            ClipOval(
              child: SizedBox(
                width: 80, height: 80,
                child: Image.asset(
                  'assets/logo01.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.rocket_launch_rounded,
                    color: _gold,
                    size: 38,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Brand text ─────────────────────────────────────────────────────────────
  Widget _buildBrandText() {
    return Column(children: [

      // Nome do app
      ShaderMask(
        shaderCallback: (b) => const LinearGradient(
          colors: [_gold, Color(0xFFF5C842)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(b),
        child: const Text('MesclaInvest',
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
      const SizedBox(height: 8),

      // Tagline
      const Text('O FUTURO DOS SEUS INVESTIMENTOS',
        style: TextStyle(
          fontSize: 10,
          color: _white30,
          letterSpacing: 2.8,
          fontWeight: FontWeight.w400,
        ),
      ),
    ]);
  }

  // ── Progress bar ───────────────────────────────────────────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Column(children: [

        // Track
        Container(
          height: 2,
          decoration: BoxDecoration(
            color: _white10,
            borderRadius: BorderRadius.circular(2),
          ),
          child: AnimatedBuilder(
            animation: _barProgress,
            builder: (_, __) => FractionallySizedBox(
              widthFactor: _barProgress.value,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_goldDim, _gold, Color(0xFFF5C842)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Label "Carregando..."
        AnimatedBuilder(
          animation: _barProgress,
          builder: (_, __) {
            final pct = (_barProgress.value * 100).round();
            return Text('$pct%',
              style: const TextStyle(
                fontSize: 11,
                color: _white30,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
      ]),
    );
  }

  // ── Atmospheric background ─────────────────────────────────────────────────
  Widget _buildGlows(Size size) {
    return Positioned.fill(
      child: Stack(children: [

        // Glow superior direito — azul
        Positioned(
          top: -120, right: -100,
          child: Container(
            width: 340, height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF1A3A8F).withOpacity(0.22),
                Colors.transparent,
              ]),
            ),
          ),
        ),

        // Glow inferior esquerdo — dourado
        Positioned(
          bottom: -80, left: -80,
          child: Container(
            width: 280, height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _gold.withOpacity(0.10),
                Colors.transparent,
              ]),
            ),
          ),
        ),

        // Glow central sutil — fundo do logo
        Positioned(
          top: size.height * 0.28, left: 0, right: 0,
          child: Center(
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _gold.withOpacity(0.06),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}