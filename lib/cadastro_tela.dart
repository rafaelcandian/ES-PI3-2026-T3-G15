import 'package:flutter/material.dart';
import 'app_theme.dart';

class CadastroTela extends StatefulWidget {
  const CadastroTela({super.key});

  @override
  State<CadastroTela> createState() => _CadastroTelaState();
}

class _CadastroTelaState extends State<CadastroTela> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Criar conta",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.destaque,
                  ),
                ),

                const SizedBox(height: 20),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      campoTexto(
                        nomeController,
                        'Nome Completo',
                        'Ex: Roberto Silva',
                      ),
                      const SizedBox(height: 10),

                      campoTexto(
                        emailController,
                        'E-mail',
                        'nome@exemplo.com',
                      ),
                      const SizedBox(height: 10),

                      campoTexto(
                        cpfController,
                        'CPF',
                        '000.000.000-00',
                      ),
                      const SizedBox(height: 10),

                      campoTexto(
                        telefoneController,
                        'Telefone',
                        '(00) 00000-0000',
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: senhaController,
                        obscureText: true,
                        decoration: inputDecoration('Senha', ''),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira uma senha';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      _isLoading
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                AppColors.destaque,
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _submitForm,
                              child: const Text(
                                "Cadastrar",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextFormField campoTexto(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return TextFormField(
      controller: controller,
      decoration: inputDecoration(label, hint),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Campo obrigatório';
        }

        if (label == 'E-mail' && !value.contains('@')) {
          return 'Por favor, insira um e-mail válido';
        }

        return null;
      },
    );
  }

  InputDecoration inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cadastro realizado com sucesso!"),
          ),
        );
      });
    }
  }
}