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
import 'package:mescla_invest/widgets/shared/gradient_button.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final cpfController = TextEditingController();
  final telefoneController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _aceitouTermos = false;

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

    senhaController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    cpfController.dispose();
    telefoneController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool validarCPF(String cpf) {
    final numeros = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    if (numeros.length != 11) return false;
    if (RegExp(r'^(\d)\1*$').hasMatch(numeros)) return false;

    int calcularDigito(String base) {
      int soma = 0;

      for (int i = 0; i < base.length; i++) {
        soma += int.parse(base[i]) * (base.length + 1 - i);
      }

      final resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    }

    final primeiroDigito = calcularDigito(numeros.substring(0, 9));
    final segundoDigito = calcularDigito(numeros.substring(0, 10));

    return primeiroDigito == int.parse(numeros[9]) &&
        segundoDigito == int.parse(numeros[10]);
  }

  bool validarTelefone(String telefone) {
    final numeros = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    return numeros.length == 11;
  }

  bool validarSenha(String senha) {
    return senha.length >= 6 && RegExp(r'[0-9]').hasMatch(senha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white.withValues(alpha: 0.6),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const AuthHeader(
                      title: 'Criar conta',
                      subtitle:
                      'Preencha seus dados para acessar a Mescla Invest',
                    ),
                    const SizedBox(height: 28),
                    _buildFormCard(),
                    const SizedBox(height: 20),
                    _buildLoginRedirect(),
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

  Widget _buildFormCard() {
    return AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section(
            title: 'Dados pessoais',
            children: [
              _authInput(
                label: 'Nome completo',
                controller: nomeController,
                hint: 'Ex: Roberto Silva',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                validator: _validarNome,
              ),
              _authInput(
                label: 'E-mail',
                controller: emailController,
                hint: 'nome@exemplo.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _validarEmail,
              ),
            ],
          ),
          _divider(),
          _section(
            title: 'Documentos',
            children: [
              _authInput(
                label: 'CPF',
                controller: cpfController,
                hint: '000.000.000-00',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CpfInputFormatter(),
                ],
                validator: _validarCampoCpf,
              ),
              _authInput(
                label: 'Telefone celular',
                controller: telefoneController,
                hint: '(00) 00000-0000',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TelefoneInputFormatter(),
                ],
                validator: _validarCampoTelefone,
              ),
            ],
          ),
          _divider(),
          _section(
            title: 'Segurança',
            children: [
              _authInput(
                label: 'Senha',
                controller: senhaController,
                hint: 'Mínimo 6 caracteres e 1 número',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: _visibilityButton(
                  isObscure: _obscurePassword,
                  onTap: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                validator: _validarCampoSenha,
              ),
              const SizedBox(height: 8),
              _buildPasswordStrengthBar(),
              const SizedBox(height: 14),
              _authInput(
                label: 'Confirmar senha',
                controller: confirmarSenhaController,
                hint: 'Digite novamente a senha',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscureConfirmPassword,
                suffixIcon: _visibilityButton(
                  isObscure: _obscureConfirmPassword,
                  onTap: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                validator: _validarConfirmacaoSenha,
              ),
            ],
          ),
          _divider(),
          _buildTermosCheckbox(),
          const SizedBox(height: 22),
          _buildCadastrarButton(),
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

  Widget _section({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthSectionLabel(label: title),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }

  Widget _authInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthFieldLabel(
            label: label,
            required: true,
          ),
          const SizedBox(height: 7),
          AuthTextField(
            controller: controller,
            hint: hint,
            icon: icon,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            obscureText: obscureText,
            suffixIcon: suffixIcon,
            inputFormatters: inputFormatters,
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _visibilityButton({
    required bool isObscure,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(
        isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: Colors.white.withValues(alpha: 0.35),
        size: 20,
      ),
      onPressed: onTap,
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 18),
      child: Divider(
        color: Colors.white.withValues(alpha: 0.07),
        thickness: 0.5,
      ),
    );
  }

  String? _validarNome(String? value) {
    final nome = value?.trim() ?? '';

    if (nome.isEmpty) return 'Campo obrigatório';
    if (nome.split(' ').length < 2) return 'Informe nome e sobrenome';

    return null;
  }

  String? _validarEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) return 'Campo obrigatório';

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return 'E-mail inválido';
    }

    return null;
  }

  String? _validarCampoCpf(String? value) {
    final cpf = value?.trim() ?? '';

    if (cpf.isEmpty) return 'Campo obrigatório';
    if (!validarCPF(cpf)) return 'CPF inválido';

    return null;
  }

  String? _validarCampoTelefone(String? value) {
    final telefone = value?.trim() ?? '';

    if (telefone.isEmpty) return 'Campo obrigatório';
    if (!validarTelefone(telefone)) return 'Telefone inválido';

    return null;
  }

  String? _validarCampoSenha(String? value) {
    final senha = value ?? '';

    if (senha.isEmpty) return 'Campo obrigatório';

    if (!validarSenha(senha)) {
      return 'Senha fraca: mínimo 6 caracteres e 1 número';
    }

    return null;
  }

  String? _validarConfirmacaoSenha(String? value) {
    final confirmacao = value ?? '';

    if (confirmacao.isEmpty) return 'Confirme sua senha';
    if (confirmacao != senhaController.text) return 'As senhas não coincidem';

    return null;
  }

  Widget _buildPasswordStrengthBar() {
    final senha = senhaController.text;

    if (senha.isEmpty) return const SizedBox.shrink();

    int forca = 0;

    if (senha.length >= 6) forca++;
    if (senha.length >= 10) forca++;
    if (senha.contains(RegExp(r'[A-Z]'))) forca++;
    if (senha.contains(RegExp(r'[0-9]'))) forca++;
    if (senha.contains(RegExp(r'[!@#\$%^&*]'))) forca++;

    final labels = [
      '',
      'Fraca',
      'Razoável',
      'Boa',
      'Forte',
      'Muito forte',
    ];

    final colors = [
      Colors.transparent,
      Colors.red,
      Colors.orange,
      AppColors.destaque,
      AppColors.destaqueClaro,
      AppColors.destaqueEscuro,
    ];

    return Row(
      children: [
        ...List.generate(5, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
              height: 3,
              decoration: BoxDecoration(
                color: index < forca
                    ? colors[forca]
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: 10),
        Text(
          labels[forca],
          style: TextStyle(
            fontSize: 11,
            color: colors[forca],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTermosCheckbox() {
    return GestureDetector(
      onTap: () {
        setState(() => _aceitouTermos = !_aceitouTermos);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color:
                _aceitouTermos ? AppColors.destaque : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _aceitouTermos
                      ? AppColors.destaque
                      : Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: _aceitouTermos
                  ? const Icon(
                Icons.check_rounded,
                color: Colors.black,
                size: 15,
              )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.5,
                ),
                children: const [
                  TextSpan(text: 'Li e aceito os '),
                  TextSpan(
                    text: 'Termos de Uso',
                    style: TextStyle(
                      color: AppColors.destaque,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(text: ' e a '),
                  TextSpan(
                    text: 'Política de Privacidade',
                    style: TextStyle(
                      color: AppColors.destaque,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(text: ' da MesclaInvest'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCadastrarButton() {
    return GradientButton(
      label: 'Cadastrar',
      loading: _isLoading,
      radius: 14,
      onTap: _isLoading ? null : _validarEEnviarCadastro,
    );
  }

  Widget _buildLoginRedirect() {
    return GestureDetector(
      onTap: () => Navigator.pushReplacementNamed(context, '/login'),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          children: const [
            TextSpan(text: 'Já possui uma conta institucional? '),
            TextSpan(
              text: 'Fazer login',
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

  void _validarEEnviarCadastro() {
    if (!_aceitouTermos) {
      _showSnackBar(
        'Aceite os Termos de Uso e a Política de Privacidade para continuar.',
        error: true,
      );
      return;
    }

    _submitForm();
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();

    final formValido = _formKey.currentState?.validate() ?? false;

    if (!formValido) {
      _showSnackBar(
        'Revise os campos destacados antes de continuar.',
        error: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final errorMessage = await _auth.register(
        nome: nomeController.text.trim(),
        email: emailController.text.trim(),
        cpf: cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        telefone: telefoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        senha: senhaController.text,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (errorMessage == null) {
        _showSuccessDialog();
      } else {
        _showSnackBar(errorMessage, error: true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      _showSnackBar(
        'Erro ao realizar cadastro: $e',
        error: true,
      );
    }
  }

  void _showSnackBar(
      String message, {
        bool success = false,
        bool error = false,
      }) {
    AppSnackBar.show(
      context,
      message: message,
      success: success,
      error: error,
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: AuthCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.destaqueClaro,
                        AppColors.destaqueEscuro,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.destaque.withValues(alpha: 0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.black,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Conta criada com sucesso!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.destaque,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Seu acesso foi cadastrado. Agora você já pode fazer login na Mescla Invest.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.58),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),
                GradientButton(
                  label: 'Ir para login',
                  radius: 14,
                  height: 50,
                  onTap: () {
                    Navigator.pop(dialogContext);
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.length > 11) {
      text = text.substring(0, 11);
    }

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');

      buffer.write(text[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}

class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.length > 11) {
      text = text.substring(0, 11);
    }

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == 7) buffer.write('-');

      buffer.write(text[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}