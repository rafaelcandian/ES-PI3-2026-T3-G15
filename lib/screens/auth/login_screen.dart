import 'package:flutter/material.dart';
import 'package:mescla_invest/services/autenticacao.dart';
import 'app_theme.dart';
import 'cadastro_screen.dart';
import 'recuperacao_senha_screen.dart';

class LoginTela extends StatefulWidget {
  const LoginTela({super.key});

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final AuthService _auth = AuthService();

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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildBrandSection(),
                      const SizedBox(height: 28),
                      _buildLoginCard(),
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
      ),
    );
  }

  // ─── BRAND ──────────────────────────────────────────────────────────────────

  Widget _buildBrandSection() {
    return Column(
      children: [
        // Logo feita pelo seu amigo
        Image.asset(
          'assets/logo01.png',
          width: 200,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 10),
        Text(
          'O FUTURO DOS SEUS INVESTIMENTOS',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.35),
            letterSpacing: 2.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ─── CARD ────────────────────────────────────────────────────────────────────

  Widget _buildLoginCard() {
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
          const Text(
            'Bem-vindo',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.destaque,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Acesse sua conta para continuar.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.5),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // E-mail
          _fieldLabel('E-mail'),
          const SizedBox(height: 7),
          _buildTextField(
            controller: emailController,
            icon: Icons.email_outlined,
            hint: 'seu@email.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Senha + "Esqueci" na mesma linha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _fieldLabel('Senha'),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecuperacaoSenhaTela(),
                  ),
                ),
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
          _buildTextField(
            controller: senhaController,
            icon: Icons.lock_outline,
            hint: 'Digite sua senha',
            obscureText: _obscurePassword,
            showToggle: true,
          ),
          const SizedBox(height: 22),

          // Botão Entrar
          _buildEntrarButton(),
          const SizedBox(height: 22),

          // Divider "ou"
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: Colors.white.withOpacity(0.1),
                  thickness: 0.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ou',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Colors.white.withOpacity(0.1),
                  thickness: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Center(
            child: Text(
              'Ainda não tem uma conta?',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Botão Criar Conta
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CadastroTela()),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.12)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Criar Conta',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTÃO ENTRAR ─────────────────────────────────────────────────────────

  Widget _buildEntrarButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5A623), Color(0xFFD4880A)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5A623).withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _submitLogin,
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
              'Entrar',
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
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withOpacity(0.6),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool showToggle = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: showToggle ? _obscurePassword : obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withOpacity(0.4),
          size: 20,
        ),
        suffixIcon: showToggle
            ? IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.white.withOpacity(0.35),
            size: 20,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        )
            : null,
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
          borderSide: const BorderSide(color: AppColors.erro, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.erro, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.erro, fontSize: 11),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Campo obrigatório';
        return null;
      },
    );
  }

  // ─── LOGIN ────────────────────────────────────────────────────────────────

  void _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final error = await _auth.login(
        emailController.text.trim(),
        senhaController.text.trim(),
      );
      setState(() => _isLoading = false);
      if (!mounted) return;

      if (error == null) {
        Navigator.pushReplacementNamed(context, '/catalogo');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error, style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF1A2045),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }
}