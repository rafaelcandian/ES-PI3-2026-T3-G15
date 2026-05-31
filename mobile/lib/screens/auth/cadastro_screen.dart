// ==========================================
// ARQUIVO COMENTADO AUTOMATICAMENTE
// Projeto: MesclaInvest
// ==========================================


// Este arquivo é responsável pela tela de cadastro.
// Aqui são realizadas:
// - validações dos campos
// - criação de conta
// - tratamento de erros
// - integração com Firebase
// - feedback visual para o usuário

/* Victória Nobre - 25016398 */

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

/* Orquestrador de Registro de Usuários (User Provisioning).
   Gerencia o ciclo de vida do formulário de adesão, implementando validações algorítmicas 
   locais e a sincronização assíncrona com o Firebase Auth e Firestore. */
class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final cpfController = TextEditingController();
  final telefoneController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  /* Controla o estado de submissão do formulário. */
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _aceitouTermos = false;

  @override
  void initState() {
    super.initState();
    senhaController.addListener(_atualizarForcaSenha);
  }

  void _atualizarForcaSenha() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    senhaController.removeListener(_atualizarForcaSenha);

    nomeController.dispose();
    emailController.dispose();
    cpfController.dispose();
    telefoneController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();

    super.dispose();
  }

  /* Validação de Integridade de Identidade (CPF).
     Implementa o algoritmo de validação de dígitos verificadores (Módulo 11) conforme 
     especificação da Receita Federal. Previne a entrada de dados sintaticamente inválidos
     antes mesmo da chamada à API, economizando recursos de rede e processamento. */
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

  /* Verifica se o telefone possui a quantidade correta de dígitos. */
  bool validarTelefone(String telefone) {
    final numeros = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    return numeros.length == 11;
  }

  /* Exige requisitos mínimos de segurança para a senha do usuário. */
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
          tooltip: 'Voltar',
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white.withValues(alpha: 0.82),
            size: 21,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const AuthHeader(
                  title: 'Criar conta',
                  subtitle:
                  'Preencha seus dados para começar a usar a Mescla Invest.',
                ),
                const SizedBox(height: 28),
                _buildFormCard(),
                const SizedBox(height: 22),
                _buildLoginRedirect(),
                const SizedBox(height: 24),
                const AuthFooter(),
              ],
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
              const SizedBox(height: 16),
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
          const SizedBox(height: 24),
          _buildCadastrarButton(),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '* Campos obrigatórios',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthSectionLabel(label: title),
        const SizedBox(height: 15),
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
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthFieldLabel(label: label, required: true),
          const SizedBox(height: 8),
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
      tooltip: isObscure ? 'Mostrar senha' : 'Ocultar senha',
      icon: Icon(
        isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: Colors.white.withValues(alpha: 0.58),
        size: 21,
      ),
      onPressed: onTap,
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Divider(
        color: Colors.white.withValues(alpha: 0.1),
        thickness: 0.6,
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
      return 'Senha fraca: use no mínimo 6 caracteres e 1 número';
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

    final labels = ['', 'Fraca', 'Razoável', 'Boa', 'Forte', 'Muito forte'];

    final colors = [
      Colors.transparent,
      Colors.redAccent,
      Colors.orangeAccent,
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
              height: 4,
              decoration: BoxDecoration(
                color: index < forca
                    ? colors[forca]
                    : Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
        const SizedBox(width: 12),
        Text(
          labels[forca],
          style: TextStyle(
            fontSize: 12.5,
            color: colors[forca],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /* Garante o consentimento do usuário quanto às diretrizes da plataforma. */
  Widget _buildTermosCheckbox() {
    return GestureDetector(
      onTap: () {
        setState(() => _aceitouTermos = !_aceitouTermos);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 23,
            height: 23,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                color: _aceitouTermos ? AppColors.destaque : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _aceitouTermos
                      ? AppColors.destaque
                      : Colors.white.withValues(alpha: 0.42),
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
                  fontSize: 13.2,
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.45,
                ),
                children: const [
                  TextSpan(text: 'Li e aceito os '),
                  TextSpan(
                    text: 'Termos de Uso',
                    style: TextStyle(
                      color: AppColors.destaque,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' e a '),
                  TextSpan(
                    text: 'Política de Privacidade',
                    style: TextStyle(
                      color: AppColors.destaque,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' da Mescla Invest.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCadastrarButton() {
    return AppButton.primary(
      label: 'Cadastrar',
      loading: _isLoading,
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
            fontSize: 14.5,
            color: Colors.white.withValues(alpha: 0.68),
            height: 1.4,
          ),
          children: const [
            TextSpan(text: 'Já tem uma conta? '),
            TextSpan(
              text: 'Entrar',
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

  /* Garante que os termos foram aceitos antes de processar o cadastro. */
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

  /* Lógica de Persistência e Provisionamento.
     1. Desacopla a interface (FocusScope.unfocus) para evitar artefatos de teclado.
     2. Realiza a chamada atômica ao AuthService.register.
     3. Trata a resposta polimórfica (sucesso ou erro tipificado) para feedback ao usuário. */
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
        _showSnackBar(_formatarErroCadastro(errorMessage), error: true);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      _showSnackBar(
        'Não foi possível criar sua conta agora. Verifique os dados e tente novamente.',
        error: true,
      );
    }
  }

  /* Mapeia erros técnicos do Firebase para mensagens amigáveis ao usuário. */
  String _formatarErroCadastro(String erro) {
    final mensagem = erro.toLowerCase();

    if (mensagem.contains('email-already-in-use') ||
        mensagem.contains('e-mail-already-in-use') ||
        mensagem.contains('already')) {
      return 'Este e-mail já está cadastrado. Tente entrar ou use outro e-mail.';
    }

    if (mensagem.contains('invalid-email') || mensagem.contains('inválido')) {
      return 'Informe um e-mail válido para continuar.';
    }

    if (mensagem.contains('weak-password') || mensagem.contains('senha')) {
      return 'A senha informada é muito fraca. Use no mínimo 6 caracteres e 1 número.';
    }

    if (mensagem.contains('network') || mensagem.contains('internet')) {
      return 'Verifique sua conexão com a internet e tente novamente.';
    }

    return erro;
  }

  void _showSnackBar(
      String message, {
        bool success = false,
        bool error = false,
      }) {
    AppSnackBar.show(context, message: message, success: success, error: error);
  }

  /* Feedback visual positivo após a criação bem-sucedida da conta. */
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
                        color: AppColors.destaque.withValues(alpha: 0.28),
                        blurRadius: 20,
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
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: AppColors.destaque,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Seu cadastro foi concluído. Agora você já pode entrar na Mescla Invest.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),
                AppButton.primary(
                  label: 'Ir para login',
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

/* Formatador de Input de Documentação (Masking).
   Aplica uma máscara dinâmica de tempo real para CPF (000.000.000-00), 
   melhorando a legibilidade e garantindo a entrada padronizada de dados. */
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
      selection: TextSelection.collapsed(offset: formatted.length),
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
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
