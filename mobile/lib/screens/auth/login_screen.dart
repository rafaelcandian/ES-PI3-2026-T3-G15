import 'package:flutter/material.dart';

import 'package:mescla_invest/services/autenticacao.dart';
import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/widgets/auth/auth_card.dart';
import 'package:mescla_invest/widgets/auth/auth_field_label.dart';
import 'package:mescla_invest/widgets/auth/auth_footer.dart';
import 'package:mescla_invest/widgets/auth/auth_header.dart';
import 'package:mescla_invest/widgets/auth/auth_section_label.dart';
import 'package:mescla_invest/widgets/auth/auth_text_field.dart';
import 'package:mescla_invest/widgets/shared/app_snackbar.dart';
import 'package:mescla_invest/widgets/shared/gradient_button.dart';

import 'cadastro_screen.dart';
import 'recuperacao_senha_screen.dart';
import 'verificacao_login_screen.dart';

class LoginTela extends StatefulWidget {
  const LoginTela({super.key});

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _autoValidate = false;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Form(
                key: _formKey,
                autovalidateMode: _autoValidate
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  children: [
                    const AuthHeader(
                      title: 'Entrar',
                      subtitle: 'Acesse sua conta institucional abaixo',
                    ),
                    const SizedBox(height: 28),
                    _buildLoginCard(),
                    const SizedBox(height: 20),
                    _buildCadastroRedirect(),
                    const SizedBox(height: 24),
                    const AuthFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthSectionLabel(label: 'Acesso institucional'),
          const SizedBox(height: 14),

          const AuthFieldLabel(
            label: 'E-mail',
            required: true,
          ),
          const SizedBox(height: 7),
          AuthTextField(
            controller: emailController,
            hint: 'seu@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validarEmail,
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AuthFieldLabel(
                label: 'Senha',
                required: true,
              ),
              GestureDetector(
                onTap: _abrirRecuperacaoSenha,
                child: const Text(
                  'Esqueci minha senha',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.destaque,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          AuthTextField(
            controller: senhaController,
            hint: 'Digite sua senha',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white.withValues(alpha: 0.35),
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: _validarSenha,
          ),

          const SizedBox(height: 22),

          GradientButton(
            label: 'Entrar',
            loading: _isLoading,
            radius: 14,
            onTap: _isLoading ? null : _submitLogin,
          ),

          const SizedBox(height: 14),

          Center(
            child: Text(
              '* Campos obrigatórios',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validarEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe seu e-mail.';
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return 'E-mail inválido. Ex: nome@dominio.com';
    }

    return null;
  }

  String? _validarSenha(String? value) {
    final senha = value ?? '';

    if (senha.isEmpty) {
      return 'Informe sua senha.';
    }

    if (senha.length < 6) {
      return 'A senha deve ter no mínimo 6 caracteres.';
    }

    return null;
  }

  Widget _buildCadastroRedirect() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CadastroPage(),
          ),
        );
      },
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          children: const [
            TextSpan(text: 'Ainda não possui uma conta? '),
            TextSpan(
              text: 'Criar conta',
              style: TextStyle(
                color: AppColors.destaque,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLogin() async {
    setState(() {
      _autoValidate = true;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final twoFactor = await _auth.startTwoFactorLogin(
        emailController.text.trim(),
        senhaController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      AppSnackBar.show(
        context,
        message: 'Codigo de verificacao enviado para seu e-mail.',
        success: true,
        duration: const Duration(seconds: 3),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificacaoLoginTela(
            email: twoFactor.email,
            senha: twoFactor.senha,
            sessionId: twoFactor.sessionId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showLoginError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showLoginError(String message) {
    AppSnackBar.show(
      context,
      message: message,
      error: true,
      duration: const Duration(seconds: 4),
    );
  }

  void _abrirRecuperacaoSenha() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RecuperacaoSenhaTela(),
      ),
    );
  }
}
