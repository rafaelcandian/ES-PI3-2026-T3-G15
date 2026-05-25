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

class VerificacaoLoginTela extends StatefulWidget {
  final String email;
  final String senha;
  final bool setupRequired;
  final String? secret;
  final String? otpAuthUri;

  const VerificacaoLoginTela({
    super.key,
    required this.email,
    required this.senha,
    required this.setupRequired,
    this.secret,
    this.otpAuthUri,
  });

  @override
  State<VerificacaoLoginTela> createState() => _VerificacaoLoginTelaState();
}

class _VerificacaoLoginTelaState extends State<VerificacaoLoginTela>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _auth = AuthService();

  String? _secret;
  String? _otpAuthUri;
  bool _isLoading = false;
  bool _isGenerating = false;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _secret = widget.secret;
    _otpAuthUri = widget.otpAuthUri;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _codigoController.dispose();
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
                  _BackButton(onTap: _voltarParaLogin),
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
                                title: 'Autenticacao em duas etapas',
                                subtitle:
                                    'Use seu app autenticador para confirmar o acesso.',
                              ),
                              const SizedBox(height: 30),
                              _buildVerificationCard(),
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

  Widget _buildVerificationCard() {
    return AuthCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthSectionLabel(label: 'Confirmacao de acesso'),
            const SizedBox(height: 14),
            Text(
              widget.setupRequired
                  ? 'Cadastre a chave abaixo no seu app autenticador e digite o codigo gerado para ativar a protecao.'
                  : 'Digite o codigo de 6 digitos exibido no seu app autenticador.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textoFraco,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (widget.setupRequired) ...[
              const SizedBox(height: 18),
              _buildSecretBox(),
            ],
            const SizedBox(height: 24),
            const AuthFieldLabel(
              label: 'Codigo do app autenticador',
              required: true,
            ),
            const SizedBox(height: 8),
            AuthTextField(
              controller: _codigoController,
              hint: '000000',
              icon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: _validarCodigo,
            ),
            const SizedBox(height: 26),
            GradientButton(
              label: 'Validar e entrar',
              loading: _isLoading,
              radius: 14,
              onTap: _isLoading ? null : _verifyCode,
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                '* Campos obrigatorios',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validarCodigo(String? value) {
    final code = value?.trim() ?? '';

    if (code.isEmpty) {
      return 'Informe o codigo.';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      return 'O codigo deve ter 6 digitos.';
    }

    return null;
  }

  Widget _buildBottomLink() {
    return Column(
      children: [
        if (widget.setupRequired) ...[
          GestureDetector(
            onTap: _isGenerating ? null : _generateNewSecret,
            child: Text(
              _isGenerating ? 'Gerando nova chave...' : 'Gerar nova chave',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.destaque,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        GestureDetector(
          onTap: _voltarParaLogin,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textoFraco,
                fontSize: 13,
              ),
              children: const [
                TextSpan(text: 'Quer usar outra conta? '),
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
        ),
      ],
    );
  }

  Widget _buildSecretBox() {
    final secret = _secret ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordaClara, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chave manual',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textoFraco,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            secret,
            style: const TextStyle(
              color: AppColors.textoPrincipal,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          if ((_otpAuthUri ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Conta: ${widget.email}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textoMuitoFraco,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _verifyCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final error = await _auth.verifyTwoFactorLogin(
      email: widget.email,
      senha: widget.senha,
      code: _codigoController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error == null) {
      AppSnackBar.show(
        context,
        message: 'Login realizado com sucesso!',
        success: true,
        duration: const Duration(seconds: 2),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/catalogo', (_) => false);
    } else {
      AppSnackBar.show(
        context,
        message: error,
        error: true,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _generateNewSecret() async {
    setState(() => _isGenerating = true);

    try {
      final result = await _auth.resetTwoFactorSetup(
        email: widget.email,
        senha: widget.senha,
      );

      if (!mounted) return;

      setState(() {
        _secret = result.secret;
        _otpAuthUri = result.otpAuthUri;
        _isGenerating = false;
      });

      AppSnackBar.show(
        context,
        message: 'Nova chave gerada. Atualize seu app autenticador.',
        success: true,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isGenerating = false);

      AppSnackBar.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  void _voltarParaLogin() {
    Navigator.pop(context);
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: onTap,
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.textoPrincipal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.bordaClara, width: 0.5),
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
