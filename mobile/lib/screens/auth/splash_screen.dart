/* Victória Nobre - 25016398 */

import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../themes/app_theme.dart';

/* Ponto de Entrada e Bootstrapping da Aplicação.
   Responsável pela inicialização de serviços globais, gestão de persistência de sessão 
   e transição de navegação baseada no estado de autenticação (Auth-state Routing). */
/*
  Tela de Splash do aplicativo.

  É a primeira tela exibida ao abrir o app.

  Responsável por:
  - mostrar animação inicial;
  - verificar sessão do usuário;
  - redirecionar para login ou catálogo.
*/
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/*
  Estado interno da SplashScreen.

  Controla:
  - animações;
  - efeitos visuais;
  - verificação de login automático.
*/
class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controller da animação principal de entrada.
  late final AnimationController _introController;
  // Controller da animação do loader circular.
  late final AnimationController _loaderController;

  // Animação de fade da tela.
  late final Animation<double> _fadeAnimation;
  // Animação de escala do conteúdo.
  late final Animation<double> _scaleAnimation;
  // Animação de movimentação vertical.
  late final Animation<Offset> _slideAnimation;

  @override
  /*
    Inicializa:
    - animações;
    - estilo do sistema;
    - verificação do usuário.
  */
  void initState() {
    super.initState();

    // Define cor da barra superior e navegação.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.fundo,
        systemNavigationBarColor: AppColors.fundo,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Controla animação de entrada da splash.
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    // Controla rotação contínua do loader.
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
        );

    // Inicia animação principal.
    _introController.forward();
    // Verifica se existe usuário logado.
    _checkUser();
  }

  /* Motor de Decisão de Roteamento.
     Aplica o padrão 'Automatic Login': verifica via SDK do Firebase a presença de 
     um JWT válido no Secure Storage local. Se presente, direciona para o catálogo 
     (Home); caso contrário, redireciona para o fluxo de autenticação primário. */
  /*
    Verifica autenticação do usuário.

    Se existir usuário logado:
    -> vai para catálogo.

    Caso contrário:
    -> vai para login.
  */
  Future<void> _checkUser() async {
    // Aguarda alguns segundos para exibir a splash.
    await Future.delayed(const Duration(milliseconds: 2800));

    if (!mounted) return;

    // Obtém usuário atualmente autenticado.
    final user = FirebaseAuth.instance.currentUser;

    // Substitui a splash pela próxima tela.
    Navigator.pushReplacementNamed(
      context,
      user != null ? '/catalogo' : '/login',
    );
  }

  @override
  /*
    Libera os controllers da memória.
  */
  void dispose() {
    _introController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  /*
    Constrói interface visual do widget.
  */
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundoEscuro,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.fundoEscuro,
              AppColors.fundo,
              AppColors.fundoEscuro,
            ],
          ),
        ),
        child: Stack(
          children: [
            const _SplashBackground(),

            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LogoGlow(),
                          const SizedBox(height: 34),
                          PremiumCircleLoader(animation: _loaderController),
                          const SizedBox(height: 22),
                          const Text(
                            'Preparando sua experiência',
                            style: TextStyle(
                              color: AppColors.textoMuitoFraco,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
  Widget responsável pelo brilho e logo principal.
*/
class _LogoGlow extends StatelessWidget {
  @override
  /*
    Constrói interface visual do widget.
  */
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 285,
          height: 285,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.destaque.withValues(alpha: 0.15),
                AppColors.destaque.withValues(alpha: 0.05),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Container(
          width: 245,
          height: 245,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.destaque.withValues(alpha: 0.07),
              width: 1,
            ),
          ),
        ),
        Image.asset('assets/logo01.png', width: 240, fit: BoxFit.contain),
      ],
    );
  }
}

/* Widget de carregamento estilizado seguindo a identidade visual premium. */
/*
  Loader circular animado personalizado.
*/
class PremiumCircleLoader extends StatelessWidget {
  // Animação utilizada para rotacionar o loader.
  final Animation<double> animation;

  const PremiumCircleLoader({super.key, required this.animation});

  @override
  /*
    Constrói interface visual do widget.
  */
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return Transform.rotate(
            angle: animation.value * 2 * math.pi,
            child: CustomPaint(painter: _PremiumCirclePainter()),
          );
        },
      ),
    );
  }
}

/* Motor de Pintura Customizado para o Loader Premium.
   Implementa animações de varredura (SweepGradient) e arcos dinâmicos via CustomPainter,
   minimizando o custo de CPU em comparação com bibliotecas de animação baseadas em imagem. */
/*
  Classe responsável por desenhar manualmente
  o loader circular utilizando Canvas.
*/
class _PremiumCirclePainter extends CustomPainter {
  @override
  /*
    Desenha os elementos gráficos do loader.
  */
  void paint(Canvas canvas, Size size) {
    // Centro do círculo.
    final center = size.center(Offset.zero);
    // Raio do loader.
    final radius = size.width / 2 - 6;

    final basePaint = Paint()
      ..color = AppColors.bordaClara
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Desenha círculo base.
    canvas.drawCircle(center, radius, basePaint);

    final glowPaint = Paint()
      ..color = AppColors.destaque.withValues(alpha: 0.12)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Desenha arco luminoso animado.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.35,
      false,
      glowPaint,
    );

    final gradientPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          Colors.transparent,
          AppColors.destaqueClaro,
          AppColors.destaque,
          AppColors.destaqueEscuro,
          Colors.transparent,
        ],
        stops: [0.0, 0.28, 0.48, 0.72, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Desenha arco luminoso animado.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.55,
      false,
      gradientPaint,
    );

    final innerPaint = Paint()
      ..color = AppColors.destaque.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 5, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/* Elementos visuais de fundo para compor a estética da marca. */
/*
  Fundo visual da splash screen.

  Responsável pelos brilhos e efeitos da tela.
*/
class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  /*
    Constrói interface visual do widget.
  */
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -140,
          right: -120,
          child: _GlowCircle(size: 320, color: AppColors.azul, opacity: 0.18),
        ),
        Positioned(
          bottom: -170,
          left: -120,
          child: _GlowCircle(
            size: 340,
            color: AppColors.destaque,
            opacity: 0.08,
          ),
        ),
        Positioned(
          top: 220,
          left: -130,
          child: _GlowCircle(size: 260, color: AppColors.roxo, opacity: 0.12),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.18)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/*
  Widget reutilizável de círculo luminoso.
*/
class _GlowCircle extends StatelessWidget {
  // Tamanho do brilho.
  final double size;
  // Cor do brilho.
  final Color color;
  // Intensidade da transparência.
  final double opacity;

  const _GlowCircle({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  /*
    Constrói interface visual do widget.
  */
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
