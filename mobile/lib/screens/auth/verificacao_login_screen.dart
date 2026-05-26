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

class _VerificacaoLoginTelaState extends State<VerificacaoLoginTela> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _auth = AuthService();

  String? _secret;
  String? _otpAuthUri;

  bool _isLoading = false;
  bool _isGenerating = false;
  bool _autoValidate = false;

  String? _feedbackMessage;
  bool _feedbackIsError = false;

  @override
  void initState() {
    super.initState();
    _secret = widget.secret;
    _otpAuthUri = widget.otpAuthUri;
  }

  @override
  void dispose() {
    _codigoController.dispose();
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
              topGlowOpacity: 0.08,
              middleGlowOpacity: 0.04,
              bottomGlowOpacity: 0.1,
            ),
            SafeArea(
              child: Column(
                children: [
                  _BackButton(onTap: _voltarParaLogin),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          const AuthHeader(
                            title: 'Autenticação em duas etapas',
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
        autovalidateMode: _autoValidate
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthSectionLabel(label: 'Confirmação de acesso'),
            const SizedBox(height: 16),
            Text(
              widget.setupRequired
                  ? 'Cadastre a chave abaixo no seu app autenticador e digite o código gerado para ativar a proteção da sua conta.'
                  : 'Digite o código de 6 dígitos exibido no seu app autenticador.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.76),
                fontSize: 14.5,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (widget.setupRequired) ...[
              const SizedBox(height: 18),
              _buildSecretBox(),
            ],
            const SizedBox(height: 24),
            const AuthFieldLabel(
              label: 'Código do app autenticador',
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
            if (_feedbackMessage != null) ...[
              const SizedBox(height: 18),
              _buildFeedbackBox(
                message: _feedbackMessage!,
                isError: _feedbackIsError,
              ),
            ],
            const SizedBox(height: 26),
            GradientButton(
              label: 'Validar e entrar',
              loading: _isLoading,
              radius: 14,
              onTap: _isLoading ? null : _verifyCode,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '* Campos obrigatórios',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.white.withValues(alpha: 0.48),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecretBox() {
    final secret = _secret ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.bordaClara,
          width: 0.7,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.vpn_key_outlined,
                color: AppColors.destaque,
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                'Chave manual',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (secret.isNotEmpty)
                IconButton(
                  tooltip: 'Copiar chave',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _copiarChave(secret),
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: AppColors.destaque,
                    size: 18,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            secret.isEmpty ? 'Chave não disponível' : secret,
            style: const TextStyle(
              color: AppColors.textoPrincipal,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              height: 1.35,
            ),
          ),
          if ((_otpAuthUri ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Conta: ${widget.email}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackBox({
    required String message,
    required bool isError,
  }) {
    final backgroundColor =
    isError ? const Color(0xFF3A1118) : const Color(0xFF102C22);

    final borderColor =
    isError ? const Color(0xFFFF7A86) : AppColors.destaque;

    final iconColor =
    isError ? const Color(0xFFFF8A95) : AppColors.destaque;

    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.verified_user_outlined;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.48),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 23,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 15.5,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validarCodigo(String? value) {
    final code = value?.trim() ?? '';

    if (code.isEmpty) {
      return 'Informe o código.';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      return 'O código deve ter 6 dígitos.';
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
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.destaque,
                decorationThickness: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        GestureDetector(
          onTap: _isLoading ? null : _voltarParaLogin,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 14.5,
                height: 1.4,
              ),
              children: const [
                TextSpan(text: 'Quer usar outra conta? '),
                TextSpan(
                  text: 'Voltar para login',
                  style: TextStyle(
                    color: AppColors.destaque,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.destaque,
                    decorationThickness: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _autoValidate = true;
      _feedbackMessage = null;
      _feedbackIsError = false;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showFeedback(
        'Informe o código de 6 dígitos para continuar.',
        isError: true,
      );
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() => _isLoading = true);

    try {
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
        _showFeedback(
          _formatarErroVerificacao(error),
          isError: true,
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      _showFeedback(
        'Não foi possível validar o código agora. Verifique os dados e tente novamente.',
        isError: true,
      );
    }
  }

  Future<void> _generateNewSecret() async {
    setState(() {
      _isGenerating = true;
      _feedbackMessage = null;
      _feedbackIsError = false;
    });

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

      _showFeedback(
        'Nova chave gerada. Atualize seu app autenticador antes de continuar.',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isGenerating = false);

      final cleanError = e.toString().replaceFirst('Exception: ', '');

      _showFeedback(
        _formatarErroVerificacao(cleanError),
        isError: true,
      );
    }
  }

  void _showFeedback(
      String message, {
        required bool isError,
      }) {
    setState(() {
      _feedbackMessage = message;
      _feedbackIsError = isError;
    });

    AppSnackBar.show(
      context,
      message: message,
      success: !isError,
      error: isError,
      duration: const Duration(seconds: 4),
    );
  }

  String _formatarErroVerificacao(String error) {
    final mensagem = error.toLowerCase().trim();

    if (mensagem.contains('invalid-code') ||
        mensagem.contains('código inválido') ||
        mensagem.contains('codigo invalido') ||
        mensagem.contains('invalid token') ||
        mensagem.contains('invalid otp')) {
      return 'Código inválido. Confira o app autenticador e tente novamente.';
    }

    if (mensagem.contains('expired') ||
        mensagem.contains('expirado') ||
        mensagem.contains('timeout')) {
      return 'O código expirou. Aguarde o próximo código no app autenticador.';
    }

    if (mensagem.contains('wrong-password') ||
        mensagem.contains('senha incorreta') ||
        mensagem.contains('invalid-credential') ||
        mensagem.contains('invalid credential')) {
      return 'Não foi possível confirmar o acesso. Faça login novamente.';
    }

    if (mensagem.contains('user-not-found') ||
        mensagem.contains('usuario nao encontrado') ||
        mensagem.contains('usuário não encontrado')) {
      return 'Usuário não encontrado. Volte para o login e confira o e-mail.';
    }

    if (mensagem.contains('network') ||
        mensagem.contains('internet') ||
        mensagem.contains('conexão')) {
      return 'Verifique sua conexão com a internet e tente novamente.';
    }

    if (mensagem.contains('too-many-requests') ||
        mensagem.contains('muitas tentativas')) {
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    }

    if (mensagem.isEmpty) {
      return 'Não foi possível validar o código. Tente novamente.';
    }

    return 'Não foi possível validar o código. Verifique as informações e tente novamente.';
  }

  void _copiarChave(String secret) {
    Clipboard.setData(ClipboardData(text: secret));

    AppSnackBar.show(
      context,
      message: 'Chave copiada.',
      success: true,
      duration: const Duration(seconds: 2),
    );
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
          tooltip: 'Voltar',
          onPressed: onTap,
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.textoPrincipal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.bordaClara,
                width: 0.6,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.destaque,
              size: 17,
            ),
          ),
        ),
      ),
    );
  }
}