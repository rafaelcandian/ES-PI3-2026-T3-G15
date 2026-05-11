import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mescla_invest/services/autenticacao.dart';
import '../../themes/app_theme.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final AuthService _auth = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _aceitouTermos = false;

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController = TextEditingController();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  static const Color _cardColor = Color(0xFF0F1440);
  static const Color _fieldColor = Color(0xFF1A2045);
  static const Color _goldLight = Color(0xFFFFD88A);
  static const Color _goldDark = Color(0xFFFFB74D);

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
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

    return true;
  }

  bool validarTelefone(String telefone) {
    telefone = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    return telefone.length == 11;
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
            color: Colors.white.withOpacity(0.6),
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
                    _buildHeader(),
                    const SizedBox(height: 28),
                    _buildFormCard(),
                    const SizedBox(height: 20),
                    _buildLoginRedirect(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/logo01.png',
          width: 160,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        const Text(
          'Criar conta',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.destaque,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Preencha seus dados para acessar a Mescla Invest',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.45),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Dados pessoais'),
          const SizedBox(height: 14),

          _fieldLabel('Nome completo', required: true),
          const SizedBox(height: 7),
          _campoTexto(
            controller: nomeController,
            hint: 'Ex: Roberto Silva',
            icon: Icons.person_outline_rounded,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              final nome = value?.trim() ?? '';

              if (nome.isEmpty) {
                return 'Campo obrigatório';
              }

              if (nome.split(' ').length < 2) {
                return 'Informe nome e sobrenome';
              }

              return null;
            },
          ),

          const SizedBox(height: 14),

          _fieldLabel('E-mail', required: true),
          const SizedBox(height: 7),
          _campoTexto(
            controller: emailController,
            hint: 'nome@exemplo.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final email = value?.trim() ?? '';

              if (email.isEmpty) {
                return 'Campo obrigatório';
              }

              if (!email.contains('@') || !email.contains('.')) {
                return 'E-mail inválido';
              }

              return null;
            },
          ),

          const SizedBox(height: 22),
          _divider(),
          const SizedBox(height: 18),

          _sectionLabel('Documentos'),
          const SizedBox(height: 14),

          _fieldLabel('CPF', required: true),
          const SizedBox(height: 7),
          TextFormField(
            controller: cpfController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CpfInputFormatter(),
            ],
            decoration: _inputDecoration(
              hint: '000.000.000-00',
              icon: Icons.badge_outlined,
            ),
            validator: (value) {
              final cpf = value?.trim() ?? '';

              if (cpf.isEmpty) {
                return 'Campo obrigatório';
              }

              if (!validarCPF(cpf)) {
                return 'CPF inválido';
              }

              return null;
            },
          ),

          const SizedBox(height: 14),

          _fieldLabel('Telefone celular', required: true),
          const SizedBox(height: 7),
          TextFormField(
            controller: telefoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TelefoneInputFormatter(),
            ],
            decoration: _inputDecoration(
              hint: '(00) 00000-0000',
              icon: Icons.phone_outlined,
            ),
            validator: (value) {
              final telefone = value?.trim() ?? '';

              if (telefone.isEmpty) {
                return 'Campo obrigatório';
              }

              if (!validarTelefone(telefone)) {
                return 'Telefone inválido';
              }

              return null;
            },
          ),

          const SizedBox(height: 22),
          _divider(),
          const SizedBox(height: 18),

          _sectionLabel('Segurança'),
          const SizedBox(height: 14),

          _fieldLabel('Senha', required: true),
          const SizedBox(height: 7),
          TextFormField(
            controller: senhaController,
            obscureText: _obscurePassword,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            decoration: _inputDecoration(
              hint: 'Mínimo 6 caracteres e 1 número',
              icon: Icons.lock_outline_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white.withOpacity(0.35),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) {
              final senha = value ?? '';

              if (senha.isEmpty) {
                return 'Campo obrigatório';
              }

              if (!validarSenha(senha)) {
                return 'Senha fraca: mínimo 6 caracteres e 1 número';
              }

              return null;
            },
          ),

          const SizedBox(height: 8),
          _buildPasswordStrengthBar(),
          const SizedBox(height: 14),

          _fieldLabel('Confirmar senha', required: true),
          const SizedBox(height: 7),
          TextFormField(
            controller: confirmarSenhaController,
            obscureText: _obscureConfirmPassword,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            decoration: _inputDecoration(
              hint: 'Digite novamente a senha',
              icon: Icons.lock_outline_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white.withOpacity(0.35),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            validator: (value) {
              final confirmacao = value ?? '';

              if (confirmacao.isEmpty) {
                return 'Confirme sua senha';
              }

              if (confirmacao != senhaController.text) {
                return 'As senhas não coincidem';
              }

              return null;
            },
          ),

          const SizedBox(height: 22),
          _divider(),
          const SizedBox(height: 18),

          _buildTermosCheckbox(),
          const SizedBox(height: 22),

          _buildCadastrarButton(),
          const SizedBox(height: 14),

          Center(
            child: Text(
              '* Campos obrigatórios',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.destaque,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.destaque,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String label, {required bool required}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 0.3,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.destaque,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _divider() {
    return Divider(
      color: Colors.white.withOpacity(0.07),
      thickness: 0.5,
    );
  }

  Widget _campoTexto({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: _inputDecoration(
        hint: hint,
        icon: icon,
      ),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.28),
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.white.withOpacity(0.4),
        size: 20,
      ),
      filled: true,
      fillColor: _fieldColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.07),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.destaque.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.erro,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.erro,
          width: 1.5,
        ),
      ),
      errorStyle: const TextStyle(
        color: AppColors.erro,
        fontSize: 11,
      ),
    );
  }

  Widget _buildPasswordStrengthBar() {
    final senha = senhaController.text;

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
      _goldLight,
      _goldDark,
    ];

    if (senha.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        ...List.generate(5, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index < 4 ? 4 : 0,
              ),
              height: 3,
              decoration: BoxDecoration(
                color: index < forca
                    ? colors[forca]
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: 10),
        Text(
          forca > 0 ? labels[forca] : '',
          style: TextStyle(
            fontSize: 11,
            color: forca > 0 ? colors[forca] : Colors.transparent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTermosCheckbox() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _aceitouTermos = !_aceitouTermos;
        });
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
                color: _aceitouTermos
                    ? AppColors.destaque
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _aceitouTermos
                      ? AppColors.destaque
                      : Colors.white.withOpacity(0.25),
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
                  color: Colors.white.withOpacity(0.55),
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
    final podeCadastrar = _aceitouTermos && !_isLoading;

    return AnimatedOpacity(
      opacity: podeCadastrar ? 1.0 : 0.55,
      duration: const Duration(milliseconds: 250),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: podeCadastrar
                ? const [
              _goldLight,
              _goldDark,
            ]
                : [
              Colors.white.withOpacity(0.18),
              Colors.white.withOpacity(0.10),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: podeCadastrar
              ? [
            BoxShadow(
              color: AppColors.destaque.withOpacity(0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _isLoading
                ? null
                : () {
              if (!_aceitouTermos) {
                _showSnackBar(
                  'Aceite os Termos de Uso e a Política de Privacidade para continuar.',
                );
                return;
              }

              _submitForm();
            },
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2.5,
                ),
              )
                  : Text(
                'Cadastrar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: podeCadastrar
                      ? Colors.black
                      : Colors.white.withOpacity(0.55),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
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
            color: Colors.white.withOpacity(0.4),
          ),
          children: const [
            TextSpan(
              text: 'Já possui uma conta institucional? ',
            ),
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

  Widget _buildFooter() {
    return Text(
      '© 2026 MESCLA INVEST  •  ACADEMIC & FINANCIAL EXCELLENCE',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 9,
        color: Colors.white.withOpacity(0.2),
        letterSpacing: 1.4,
        height: 1.8,
      ),
    );
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();

    if (!_aceitouTermos) {
      _showSnackBar('Aceite os Termos de Uso para continuar.');
      return;
    }

    final formValido = _formKey.currentState?.validate() ?? false;

    if (!formValido) {
      _showSnackBar('Revise os campos destacados antes de continuar.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final errorMessage = await _auth.register(
        nome: nomeController.text.trim(),
        email: emailController.text.trim(),
        cpf: cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        telefone: telefoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        senha: senhaController.text,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (errorMessage == null) {
        _showSuccessDialog();
      } else {
        _showSnackBar(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar('Erro ao realizar cadastro: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: _fieldColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
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
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.destaque.withOpacity(0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.55),
                  blurRadius: 40,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: AppColors.destaque.withOpacity(0.12),
                  blurRadius: 28,
                ),
              ],
            ),
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
                        _goldLight,
                        _goldDark,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.destaque.withOpacity(0.35),
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
                    color: Colors.white.withOpacity(0.58),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          _goldLight,
                          _goldDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.pop(dialogContext);
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Center(
                          child: Text(
                            'Ir para login',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
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

    String formatted = '';

    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) {
        formatted += '.';
      }

      if (i == 9) {
        formatted += '-';
      }

      formatted += text[i];
    }

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

    String formatted = '';

    for (int i = 0; i < text.length; i++) {
      if (i == 0) {
        formatted += '(';
      }

      if (i == 2) {
        formatted += ') ';
      }

      if (i == 7) {
        formatted += '-';
      }

      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}