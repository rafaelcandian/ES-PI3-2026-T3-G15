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
import 'package:mescla_invest/widgets/shared/app_button.dart';
import 'package:mescla_invest/widgets/shared/app_snackbar.dart';
import 'package:mescla_invest/widgets/shared/atmospheric_background.dart';

class RecuperacaoSenhaTela extends StatefulWidget {
  const RecuperacaoSenhaTela({super.key});

  @override
  State<RecuperacaoSenhaTela> createState() => _RecuperacaoSenhaTelaState();
}

class _RecuperacaoSenhaTelaState extends State<RecuperacaoSenhaTela> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  final AuthService _auth = AuthService();

  bool _isLoading = false;
  bool _autoValidate = false;

  String? _feedbackMessage;
  bool _feedbackIsError = false;

  @override
  void dispose() {
    _emailController.dispose();
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
                  const _BackButton(),
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
                            title: 'Recuperar senha',
                            subtitle:
                            'Informe seu e-mail para receber as instruções de redefinição.',
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
        autovalidateMode: _autoValidate
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthSectionLabel(label: 'Redefinição de senha'),
            const SizedBox(height: 16),
            Text(
              'Digite o e-mail cadastrado na sua conta. Se ele estiver registrado, enviaremos as instruções para você redefinir sua senha.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.76),
                fontSize: 14.5,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
            const AuthFieldLabel(label: 'E-mail', required: true),
            const SizedBox(height: 8),
            AuthTextField(
              controller: _emailController,
              hint: 'seu@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validarEmail,
            ),
            if (_feedbackMessage != null) ...[
              const SizedBox(height: 18),
              _buildFeedbackBox(
                message: _feedbackMessage!,
                isError: _feedbackIsError,
              ),
            ],
            const SizedBox(height: 26),
            AppButton.primary(
              label: 'Enviar link',
              loading: _isLoading,
              onTap: _isLoading ? null : _sendResetEmail,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackBox({
    required String message,
    required bool isError,
  }) {
    final backgroundColor = isError
        ? const Color(0xFF3A1118)
        : const Color(0xFF102C22);

    final borderColor = isError ? const Color(0xFFFF7A86) : AppColors.destaque;

    final iconColor = isError ? const Color(0xFFFF8A95) : AppColors.destaque;

    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.mark_email_read_outlined;

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

  String? _validarEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe o e-mail.';
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return 'E-mail inválido. Ex: nome@dominio.com';
    }

    return null;
  }

  Widget _buildBottomLink() {
    return GestureDetector(
      onTap: _isLoading ? null : () => Navigator.pop(context),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 14.5,
            height: 1.4,
          ),
          children: const [
            TextSpan(text: 'Lembrou sua senha? '),
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
    );
  }

  Future<void> _sendResetEmail() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _autoValidate = true;
      _feedbackMessage = null;
      _feedbackIsError = false;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showFeedback(
        'Informe um e-mail válido para receber o link de recuperação.',
        isError: true,
      );
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() => _isLoading = true);

    try {
      final error = await _auth.resetPassword(_emailController.text.trim());

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (error == null) {
        _showFeedback(
          'E-mail de recuperação enviado. Verifique sua caixa de entrada e o spam.',
          isError: false,
        );

        AppSnackBar.show(
          context,
          message: 'E-mail de recuperação enviado!',
          success: true,
          duration: const Duration(seconds: 4),
        );
      } else {
        _showFeedback(_formatarErroRecuperacao(error), isError: true);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      _showFeedback(
        'Não foi possível enviar o e-mail agora. Verifique sua conexão e tente novamente.',
        isError: true,
      );
    }
  }

  void _showFeedback(String message, {required bool isError}) {
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

  String _formatarErroRecuperacao(String error) {
    final mensagem = error.toLowerCase().trim();

    if (mensagem.contains('invalid-email') ||
        mensagem.contains('email inválido') ||
        mensagem.contains('e-mail inválido')) {
      return 'E-mail inválido. Verifique o endereço informado.';
    }

    if (mensagem.contains('user-not-found') ||
        mensagem.contains('usuario nao encontrado') ||
        mensagem.contains('usuário não encontrado')) {
      return 'Não encontramos uma conta com esse e-mail.';
    }

    if (mensagem.contains('network') ||
        mensagem.contains('internet') ||
        mensagem.contains('conexão')) {
      return 'Verifique sua conexão com a internet e tente novamente.';
    }

    if (mensagem.contains('too-many-requests') ||
        mensagem.contains('muitas tentativas')) {
      return 'Muitas tentativas de recuperação. Aguarde alguns minutos e tente novamente.';
    }

    return 'Não foi possível enviar o e-mail de recuperação. Tente novamente.';
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: 'Voltar',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.destaque,
            size: 20,
          ),
        ),
      ),
    );
  }
}