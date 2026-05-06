import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';

class CadastroTela extends StatefulWidget {
  const CadastroTela({super.key});

  @override
  State<CadastroTela> createState() => _CadastroTelaState();
}

class _CadastroTelaState extends State<CadastroTela>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _aceitouTermos = false;

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();

    // Atualiza barra de força ao digitar a senha
    senhaController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    cpfController.dispose();
    telefoneController.dispose();
    senhaController.dispose();
    _animationController.dispose();
    super.dispose();
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

                    // Link para login
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.4),
                          ),
                          children: const [
                            TextSpan(
                                text: 'Já possui uma conta institucional? '),
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
                    ),
                    const SizedBox(height: 24),

                    Text(
                      '© 2024 MESCLA INVEST  •  ACADEMIC & FINANCIAL EXCELLENCE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withOpacity(0.2),
                        letterSpacing: 1.4,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────────────

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
          'Preencha os dados institucionais abaixo',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.45),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ─── CARD ────────────────────────────────────────────────────────────────────

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1440),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
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
          // ── Dados pessoais ────────────────────────────────────────────────
          _sectionLabel('Dados pessoais'),
          const SizedBox(height: 14),

          _fieldLabel('Nome Completo', required: true),
          const SizedBox(height: 7),
          campoTexto(
            nomeController,
            'Nome Completo',
            'Ex: Roberto Silva',
            Icons.person_outline_rounded,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Campo obrigatório';
              if (value.trim().split(' ').length < 2)
                return 'Informe nome e sobrenome';
              return null;
            },
          ),
          const SizedBox(height: 14),

          _fieldLabel('E-mail', required: true),
          const SizedBox(height: 7),
          campoTexto(
            emailController,
            'E-mail',
            'nome@exemplo.com',
            Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Campo obrigatório';
              if (!value.contains('@') || !value.contains('.'))
                return 'E-mail inválido';
              return null;
            },
          ),
          const SizedBox(height: 22),

          _divider(),
          const SizedBox(height: 18),

          // ── Documentos ────────────────────────────────────────────────────
          _sectionLabel('Documentos'),
          const SizedBox(height: 14),

          _fieldLabel('CPF', required: true),
          const SizedBox(height: 7),
          TextFormField(
            controller: cpfController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CpfInputFormatter(),
            ],
            decoration: inputDecoration('000.000.000-00', Icons.badge_outlined),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Campo obrigatório';
              if (value.length < 14) return 'CPF incompleto';
              return null;
            },
          ),
          const SizedBox(height: 14),

          _fieldLabel('Telefone celular', required: false),
          const SizedBox(height: 7),
          TextFormField(
            controller: telefoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TelefoneInputFormatter(),
            ],
            decoration:
            inputDecoration('(00) 00000-0000', Icons.phone_outlined),
          ),
          const SizedBox(height: 22),

          _divider(),
          const SizedBox(height: 18),

          // ── Segurança ─────────────────────────────────────────────────────
          _sectionLabel('Segurança'),
          const SizedBox(height: 14),

          _fieldLabel('Senha', required: true),
          const SizedBox(height: 7),
          TextFormField(
            controller: senhaController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: inputDecoration(
              'Mínimo 6 caracteres',
              Icons.lock_outline_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white.withOpacity(0.35),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Campo obrigatório';
              if (value.length < 6) return 'Mínimo de 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 8),
          _buildPasswordStrengthBar(),
          const SizedBox(height: 22),

          _divider(),
          const SizedBox(height: 18),

          // ── Termos ────────────────────────────────────────────────────────
          _buildTermosCheckbox(),
          const SizedBox(height: 22),

          // ── Botão ─────────────────────────────────────────────────────────
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

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

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

  Widget _divider() =>
      Divider(color: Colors.white.withOpacity(0.07), thickness: 0.5);

  Widget _buildPasswordStrengthBar() {
    final senha = senhaController.text;
    int forca = 0;
    if (senha.length >= 6) forca++;
    if (senha.length >= 10) forca++;
    if (senha.contains(RegExp(r'[A-Z]'))) forca++;
    if (senha.contains(RegExp(r'[0-9]'))) forca++;
    if (senha.contains(RegExp(r'[!@#\$%^&*]'))) forca++;

    final labels = ['', 'Fraca', 'Razoável', 'Boa', 'Forte', 'Muito forte'];
    final colors = [
      Colors.transparent,
      Colors.red,
      Colors.orange,
      const Color(0xFFF5A623),
      Colors.lightGreen,
      Colors.green,
    ];

    if (senha.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        ...List.generate(5, (i) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
              height: 3,
              decoration: BoxDecoration(
                color: i < forca
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
      onTap: () => setState(() => _aceitouTermos = !_aceitouTermos),
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
                      : Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: _aceitouTermos
                  ? const Icon(Icons.check_rounded,
                  color: Colors.black, size: 15)
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
    final habilitado = _aceitouTermos && !_isLoading;

    return AnimatedOpacity(
      opacity: _aceitouTermos ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 250),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF5A623), Color(0xFFD4880A)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _aceitouTermos
              ? [
            BoxShadow(
              color: const Color(0xFFF5A623).withOpacity(0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: habilitado ? _submitForm : null,
            borderRadius: BorderRadius.circular(14),
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
                  : const Text(
                'Cadastrar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── CAMPO GENÉRICO (mantém assinatura original) ──────────────────────────

  TextFormField campoTexto(
      TextEditingController controller,
      String label,
      String hint,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
        TextCapitalization textCapitalization = TextCapitalization.none,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: inputDecoration(hint, icon),
      validator: validator ??
              (value) {
            if (value == null || value.isEmpty) return 'Campo obrigatório';
            if (label == 'E-mail' && !value.contains('@'))
              return 'E-mail inválido';
            return null;
          },
    );
  }

  /// Decoração padrão — alinhada ao design system do app
  InputDecoration inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.28),
        fontSize: 13,
      ),
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
      filled: true,
      fillColor: const Color(0xFF1A2045),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        BorderSide(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: AppColors.destaque.withOpacity(0.5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.erro, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.erro, width: 1.5),
      ),
      errorStyle: const TextStyle(color: AppColors.erro, fontSize: 11),
    );
  }

  // ─── SUBMIT ──────────────────────────────────────────────────────────────────

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (!_aceitouTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Aceite os Termos de Uso para continuar.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1A2045),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: substitua pelo seu AuthService.cadastrar(email, senha)
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Conta criada com sucesso!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1A2045),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    });
  }
}

// ─── FORMATADORES ─────────────────────────────────────────────────────────────

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 11) text = text.substring(0, 11);

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) formatted += '.';
      if (i == 9) formatted += '-';
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 11) text = text.substring(0, 11);

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 0) formatted += '(';
      if (i == 2) formatted += ') ';
      if (i == 7) formatted += '-';
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}