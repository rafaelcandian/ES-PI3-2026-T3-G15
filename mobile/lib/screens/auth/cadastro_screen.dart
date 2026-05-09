import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mescla_invest/services/autenticacao.dart';
import 'app_theme.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final AuthService _auth = AuthService();

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController = TextEditingController();

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    cpfController.dispose();
    telefoneController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  // ===== SUA VALIDAÇÃO =====
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
        backgroundColor: AppColors.fundo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.destaque),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28 ),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 25),

                    const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.destaque,
                      size: 60,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Criar conta",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.destaque,
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      "Preencha com todos os seus dados para criar sua conta no MesclaInvest.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    campoTexto(nomeController, 'Nome Completo', 'Ex: Roberto Silva', Icons.person_outline),
                    const SizedBox(height: 20),

                    campoTexto(emailController, 'E-mail', 'nome@exemplo.com', Icons.email_outlined),
                    const SizedBox(height: 20),

                    // CPF
                    TextFormField(
                      controller: cpfController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CpfInputFormatter(),
                      ],
                      decoration: inputDecoration(
                        'CPF',
                        '000.000.000-00',
                        Icons.badge_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe CPF';
                        }
                        if (!validarCPF(value)) {
                          return 'CPF inválido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // TELEFONE
                    TextFormField(
                      controller: telefoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TelefoneInputFormatter(),
                      ],
                      decoration: inputDecoration(
                        'Telefone',
                        '(00) 00000-0000',
                        Icons.phone_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe telefone';
                        }
                        if (!validarTelefone(value)) {
                          return 'Telefone inválido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // SENHA (UI dela + sua validação)
                    TextFormField(
                      controller: senhaController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDecoration(
                        'Senha',
                        'Digite sua senha',
                        Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white60,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe senha';
                        }
                        if (!validarSenha(value)) {
                          return 'Senha fraca (mín. 6 + número)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height:  20),

                    TextFormField(
                      controller: confirmarSenhaController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDecoration(
                        'Confirmar senha',
                        'Digite novamente a senha',
                        Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white60,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirme sua senha';
                        }
                        if (value != senhaController.text) {
                          return 'As senhas não coincidem';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 48),

                    _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.destaque),
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.destaque,
                                foregroundColor: Colors.black,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: const Text(
                                "Cadastrar",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 38),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== SUA LÓGICA AUTH =====
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final errorMessage = await _auth.register(
        nome: nomeController.text.trim(),
        email: emailController.text.trim(),
        cpf: cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        telefone: telefoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        senha: senhaController.text,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cadastro realizado com sucesso!")),
        );

        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e")),
      );
    }
  }

  // ===== UI DA SUA COLEGA =====
  TextFormField campoTexto(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: inputDecoration(label, hint, icon),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Campo obrigatório';
        }

        if (label == 'E-mail' && !value.contains('@')) {
          return 'E-mail inválido';
        }

        return null;
      },
    );
  }

  InputDecoration inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: AppColors.destaque),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}

// ===== FORMATTERS DA UI DELA =====

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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