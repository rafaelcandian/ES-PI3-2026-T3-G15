import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mescla_invest/services/autenticacao.dart';
import 'package:mescla_invest/themes/app_theme.dart';

import 'package:mescla_invest/widgets/auth/auth_card.dart';
import 'package:mescla_invest/widgets/auth/auth_field_label.dart';
import 'package:mescla_invest/widgets/auth/auth_footer.dart';
import 'package:mescla_invest/widgets/auth/auth_header.dart';
import 'package:mescla_invest/widgets/auth/auth_section_label.dart';
import 'package:mescla_invest/widgets/auth/auth_text_field.dart';

import 'package:mescla_invest/widgets/shared/app_snackbar.dart';
import 'package:mescla_invest/widgets/shared/atmospheric_background.dart';
import 'package:mescla_invest/widgets/shared/gradient_button.dart';

class RecuperacaoSenhaTela extends StatefulWidget {
  const RecuperacaoSenhaTela({super.key});

  @override
  State<RecuperacaoSenhaTela> createState() => _RecuperacaoSenhaTelaState();
}

class _RecuperacaoSenhaTelaState extends State<RecuperacaoSenhaTela>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  final AuthService _auth = AuthService();

  bool _isLoading = false;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.fundo,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            const AtmosphericBackground(
              topGlowOpacity: 0.12,
              middleGlowOpacity: 0.05,
              bottomGlowOpacity: 0.16,
            ),
            SafeArea(
              child: Column(
                children: [
                  _BackButton(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              const AuthHeader(
                                title: 'Recuperar senha',
                                subtitle:
                                'Informe seu e-mail para receber as instruções de acesso.',
                              ),
                              const SizedBox(height: 30),
                              _buildRecoveryCard(),
                              const SizedBox(height: 24),
                              _buildBottomLink(),
                              const SizedBox(height: 28),
                              const AuthFooter(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildRecoveryCard() {
    return AuthCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthSectionLabel(label: 'Redefinição de acesso'),
            const SizedBox(height: 14),
            Text(
              'Digite o e-mail cadastrado na sua conta. Enviaremos uma mensagem para você redefinir sua senha.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textoFraco,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const AuthFieldLabel(
              label: 'E-mail',
              required: true,
            ),
            const SizedBox(height: 8),
            AuthTextField(
              controller: _emailController,
              hint: 'seu@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validarEmail,
            ),
            const SizedBox(height: 26),
            GradientButton(
              label: 'Enviar link',
              loading: _isLoading,
              radius: 14,
              onTap: _isLoading ? null : _sendResetEmail,
            ),
          ],
        ),
      ),
    );
  }

  String? _validarEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe o e-mail';
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return 'E-mail inválido';
    }

    return null;
  }

  Widget _buildBottomLink() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textoFraco,
            fontSize: 13,
          ),
          children: const [
            TextSpan(text: 'Lembrou sua senha? '),
            TextSpan(
              text: 'Voltar para login',
              style: TextStyle(
                color: AppColors.destaque,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendResetEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    HapticFeedback.mediumImpact();

    setState(() => _isLoading = true);

    try {
      final error = await _auth.resetPassword(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (error == null) {
        AppSnackBar.show(
          context,
          message: 'E-mail de recuperação enviado!',
          success: true,
        );

        Navigator.pop(context);
      } else {
        AppSnackBar.show(
          context,
          message: error,
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      AppSnackBar.show(
        context,
        message: 'Erro ao enviar recuperação: $e',
        error: true,
      );
    }
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.textoPrincipal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.bordaClara,
                width: 0.5,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.destaque,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}