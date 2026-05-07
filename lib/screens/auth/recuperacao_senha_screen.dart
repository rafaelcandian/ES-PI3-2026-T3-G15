import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mescla_invest/services/autenticacao.dart';
import 'package:mescla_invest/screens/auth/app_theme.dart';

class RecuperacaoSenhaTela extends StatefulWidget {
  const RecuperacaoSenhaTela({super.key});

  @override
  State<RecuperacaoSenhaTela> createState() => _RecuperacaoSenhaTelaState();
}

class _RecuperacaoSenhaTelaState extends State<RecuperacaoSenhaTela>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailFocused = false;

  final _auth = AuthService();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Cores inline para manter independência do app_theme
  static const _bg       = Color(0xFF0D1117);
  static const _surface  = Color(0xFF161C2D);
  static const _surfaceUp = Color(0xFF1C2540);
  static const _gold     = Color(0xFFEFAD1A);   // laranja-âmbar do print
  static const _goldGlow = Color(0x22EFAD1A);
  static const _goldBorder = Color(0x44EFAD1A);
  static const _white    = Colors.white;
  static const _white60  = Color(0x99FFFFFF);
  static const _white30  = Color(0x4DFFFFFF);
  static const _white10  = Color(0x1AFFFFFF);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.10), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── Send reset email ───────────────────────────────────────────────────────
  Future<void> _sendResetEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final error = await _auth.resetPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (error == null) {
        _showSnack('E-mail de recuperação enviado!', success: true);
        Navigator.pop(context);
      } else {
        _showSnack(error);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Erro: $e');
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          success ? Icons.check_circle_outline : Icons.error_outline,
          color: success ? _gold : Colors.redAccent,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
            style: const TextStyle(color: _white, fontSize: 13))),
      ]),
      backgroundColor: _surfaceUp,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(40),
        side: BorderSide(
          color: success ? _goldBorder : Colors.redAccent.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      duration: const Duration(seconds: 3),
      elevation: 0,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        resizeToAvoidBottomInset: true,
        body: Stack(children: [
          // Atmospheric glows
          _buildGlows(),

          SafeArea(
            child: Column(children: [
              // Back button
              _buildBackButton(),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(children: [
                        const SizedBox(height: 12),

                        // Logo + brand
                        _buildBrand(),
                        const SizedBox(height: 36),

                        // Main card
                        _buildCard(),
                        const SizedBox(height: 28),

                        // Bottom link
                        _buildBottomLink(),
                        const SizedBox(height: 32),

                        // Footer
                        _buildFooter(),
                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Atmospheric background glows ───────────────────────────────────────────
  Widget _buildGlows() {
    return Positioned.fill(
      child: Stack(children: [
        Positioned(
          top: -100, left: -80,
          child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _gold.withOpacity(0.12),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 40, right: -100,
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF1A3A8F).withOpacity(0.18),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Back button ────────────────────────────────────────────────────────────
  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          icon: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _white10, width: 0.5),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _gold,
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // ── Brand (rocket + name + tagline) ───────────────────────────────────────
  Widget _buildBrand() {
    return Column(children: [
      // Rocket icon with glow ring
      Container(
        width: 68, height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _goldGlow,
          border: Border.all(color: _goldBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: _gold.withOpacity(0.20),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.rocket_launch_rounded, color: _gold, size: 32),
      ),
      const SizedBox(height: 14),

      // App name
      const Text('MesclaInvest',
        style: TextStyle(
          fontFamily: 'Syne',
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: _gold,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 4),

      // Tagline
      const Text('O FUTURO DOS SEUS INVESTIMENTOS',
        style: TextStyle(
          fontSize: 10,
          color: _white30,
          letterSpacing: 2.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    ]);
  }

  // ── Main card ──────────────────────────────────────────────────────────────
  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _white10, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Card title
          const Text('Recuperar Senha',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Informe seu e-mail cadastrado para receber o link de recuperação.',
            style: TextStyle(fontSize: 13, color: _white60, height: 1.5),
          ),
          const SizedBox(height: 28),

          // E-mail label
          const Text('E-mail',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _white60,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),

          // E-mail field
          Focus(
            onFocusChange: (v) => setState(() => _emailFocused = v),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: _white, fontSize: 15),
              cursorColor: _gold,
              decoration: InputDecoration(
                hintText: 'seu@email.com',
                hintStyle: const TextStyle(color: _white30, fontSize: 14),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: _emailFocused ? _gold : _white30,
                  size: 20,
                ),
                filled: true,
                fillColor: _white10,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _white10, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _gold, width: 1.2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: Colors.redAccent.withOpacity(0.6), width: 0.8),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: Colors.redAccent, width: 1.2),
                ),
                errorStyle: const TextStyle(
                    fontSize: 11, color: Colors.redAccent),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                  return 'E-mail inválido';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 28),

          // CTA button
          _isLoading
              ? const Center(
            child: SizedBox(
              width: 26, height: 26,
              child: CircularProgressIndicator(
                color: _gold,
                strokeWidth: 2,
              ),
            ),
          )
              : _buildCTAButton(),
        ]),
      ),
    );
  }

  // ── CTA Button ─────────────────────────────────────────────────────────────
  Widget _buildCTAButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD9960E), Color(0xFFEFAD1A), Color(0xFFF5C842)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _gold.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _sendResetEmail,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: const Color(0xFF0D1117),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Enviar código',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom link ────────────────────────────────────────────────────────────
  Widget _buildBottomLink() {
    return Column(children: [
      const Text('Não recebeu o e-mail?',
        style: TextStyle(color: _white30, fontSize: 13),
      ),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: _white10,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _white10, width: 0.5),
          ),
          child: const Center(
            child: Text('Tentar outro e-mail',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _white60,
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return const Text(
      '© 2024 MESCLAINVEST • ACADEMIC & FINANCIAL EXCELLENCE',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 9,
        color: _white30,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}