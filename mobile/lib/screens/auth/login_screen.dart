/* Victória Nobre - 25016398 */

import 'package:flutter/material.dart';

import 'package:mescla_invest/services/autenticacao.dart';
import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/widgets/shared/app_button.dart';
import 'package:mescla_invest/widgets/auth/auth_card.dart';
import 'package:mescla_invest/widgets/auth/auth_field_label.dart';
import 'package:mescla_invest/widgets/auth/auth_footer.dart';
import 'package:mescla_invest/widgets/auth/auth_header.dart';
import 'package:mescla_invest/widgets/auth/auth_section_label.dart';
import 'package:mescla_invest/widgets/auth/auth_text_field.dart';
import 'package:mescla_invest/widgets/shared/app_snackbar.dart';

import 'cadastro_screen.dart';
import 'recuperacao_senha_screen.dart';
import 'verificacao_login_screen.dart';

/* Tela de login principal que gerencia o primeiro fator de autenticação e redirecionamento para 2FA. */
class LoginTela extends StatefulWidget {
  const LoginTela({super.key});

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela> {
  /* GlobalKey necessária para validar o formulário e acessar os campos de texto. */
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  /* Estados de controle da UI: loading para feedback visual e obscurePassword para privacidade. */
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _autoValidate = false;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  subtitle: 'Acesse sua conta para continuar na Mescla Invest.',
                ),
                const SizedBox(height: 28),
                _buildLoginCard(),
                const SizedBox(height: 22),
                _buildCadastroRedirect(),
                const SizedBox(height: 24),
                const AuthFooter(),
              ],
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
          const AuthSectionLabel(label: 'Acesso à conta'),
          const SizedBox(height: 16),
          const AuthFieldLabel(label: 'E-mail', required: true),
          const SizedBox(height: 8),
          AuthTextField(
            controller: emailController,
            hint: 'seu@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validarEmail,
          ),
          const SizedBox(height: 15),
          const AuthFieldLabel(label: 'Senha', required: true),
          const SizedBox(height: 8),
          AuthTextField(
            controller: senhaController,
            hint: 'Digite sua senha',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white.withValues(alpha: 0.58),
                size: 21,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: _validarSenha,
          ),
          const SizedBox(height: 10),
          _buildForgotPasswordLink(),
          const SizedBox(height: 26),
          AppButton.primary(
            label: 'Entrar',
            loading: _isLoading,
            onTap: _isLoading ? null : _submitLogin,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '* Campos obrigatórios',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* Link simples para recuperação de senha, conforme padrão visual de UX. */
  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: _isLoading ? null : _abrirRecuperacaoSenha,
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Text(
            'Esqueci minha senha',
            style: TextStyle(
              color: AppColors.destaque,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.destaque,
            ),
          ),
        ),
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
      onTap: _isLoading
          ? null
          : () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CadastroPage()),
        );
      },
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(color: Colors.white.withValues(alpha: 0.68)),
          children: const [
            TextSpan(text: 'Ainda não tem uma conta? '),
            TextSpan(
              text: 'Criar conta',
              style: TextStyle(
                color: AppColors.destaque,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* Inicia o processo de autenticação, tratando login simples e 2FA. */
  Future<void> _submitLogin() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _autoValidate = true;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showLoginError('Preencha e-mail e senha corretamente para continuar.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = emailController.text.trim();
      final senha = senhaController.text.trim();

      final twoFactor = await _auth.startTwoFactorLogin(email, senha);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      /* Se o usuário não tiver 2FA ativo, segue para o catálogo. */
      if (!twoFactor.requiresVerification && !twoFactor.setupRequired) {
        AppSnackBar.show(
          context,
          message: 'Login realizado com sucesso!',
          success: true,
          duration: const Duration(seconds: 2),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/catalogo',
              (_) => false,
        );

        return;
      }

      /* Caso precise de 2FA, navega para a tela de verificação. */
      AppSnackBar.show(
        context,
        message: twoFactor.setupRequired
            ? 'Configure seu app autenticador para concluir o acesso.'
            : 'Informe o código do seu app autenticador.',
        success: true,
        duration: const Duration(seconds: 4),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificacaoLoginTela(
            email: twoFactor.email,
            senha: twoFactor.senha,
            setupRequired: twoFactor.setupRequired,
            secret: twoFactor.secret,
            otpAuthUri: twoFactor.otpAuthUri,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final cleanError = e.toString().replaceFirst('Exception: ', '');
      _showLoginError(cleanError);
    }
  }

  void _showLoginError(String message) {
    final friendlyMessage = _formatarErroLogin(message);

    AppSnackBar.show(
      context,
      message: friendlyMessage,
      error: true,
      duration: const Duration(seconds: 4),
    );
  }

  /* Converte códigos de erro técnicos em mensagens compreensíveis. */
  String _formatarErroLogin(String message) {
    final lowerMessage = message.toLowerCase().trim();

    if (lowerMessage.contains('user-not-found') ||
        lowerMessage.contains('usuario nao encontrado') ||
        lowerMessage.contains('usuário não encontrado')) {
      return 'Usuário não encontrado. Confira o e-mail ou crie uma conta.';
    }

    if (lowerMessage.contains('wrong-password') ||
        lowerMessage.contains('senha incorreta') ||
        lowerMessage.contains('invalid-credential') ||
        lowerMessage.contains('invalid credential')) {
      return 'E-mail ou senha incorretos. Verifique os dados e tente novamente.';
    }

    if (lowerMessage.contains('invalid-email') ||
        lowerMessage.contains('email inválido') ||
        lowerMessage.contains('e-mail inválido')) {
      return 'E-mail inválido. Verifique o endereço informado.';
    }

    if (lowerMessage.contains('too-many-requests') ||
        lowerMessage.contains('muitas tentativas')) {
      return 'Muitas tentativas de login. Aguarde alguns minutos e tente novamente.';
    }

    if (lowerMessage.contains('network') ||
        lowerMessage.contains('internet') ||
        lowerMessage.contains('conexão')) {
      return 'Verifique sua conexão com a internet e tente novamente.';
    }

    if (lowerMessage.contains('disabled') ||
        lowerMessage.contains('desativada')) {
      return 'Esta conta está desativada. Entre em contato com o suporte.';
    }

    if (lowerMessage.isEmpty ||
        lowerMessage.contains('erro ao iniciar') ||
        lowerMessage.contains('erro ao entrar')) {
      return 'Não foi possível entrar agora. Tente novamente.';
    }

    return 'Não foi possível entrar. Verifique e-mail e senha e tente novamente.';
  }

  /* Navegação para o fluxo de recuperação de acesso. */
  void _abrirRecuperacaoSenha() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecuperacaoSenhaTela()),
    );
  }
}
