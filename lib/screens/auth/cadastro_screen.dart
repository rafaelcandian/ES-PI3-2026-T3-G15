import 'package:flutter/material.dart';
import 'package:mescla_invest/services/autenticacao.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    cpfController.dispose();
    telefoneController.dispose();
    senhaController.dispose();
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
      backgroundColor: const Color(0xFF10184e),

      appBar: AppBar(
        title: const Text('Criar Conta'),
        backgroundColor: const Color(0xFF10184e),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,

              child: Column(
                children: [

                  const Text(
                    "Criar conta",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.orangeAccent,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // NOME
                  TextFormField(
                    controller: nomeController,
                    style: const TextStyle(color: Colors.black87), // 🔥 MELHORIA
                    decoration: const InputDecoration(labelText: 'Nome Completo'),
                    validator: (value) =>
                        value == null || value.isEmpty
                            ? 'Informe o nome'
                            : null,
                  ),

                  const SizedBox(height: 10),

                  // EMAIL
                  TextFormField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.black87), // 🔥 MELHORIA
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    validator: (value) =>
                        value == null || !value.contains('@')
                            ? 'E-mail inválido'
                            : null,
                  ),

                  const SizedBox(height: 10),

                  // CPF
                  TextFormField(
                    controller: cpfController,
                    style: const TextStyle(color: Colors.black87), // 🔥 MELHORIA
                    decoration: const InputDecoration(labelText: 'CPF'),
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

                  const SizedBox(height: 10),

                  // TELEFONE
                  TextFormField(
                    controller: telefoneController,
                    style: const TextStyle(color: Colors.black87), // 🔥 MELHORIA
                    decoration: const InputDecoration(labelText: 'Telefone'),
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

                  const SizedBox(height: 10),

                  // SENHA
                  TextFormField(
                    controller: senhaController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.black87), // 🔥 MELHORIA
                    decoration: const InputDecoration(labelText: 'Senha'),
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

                  // 🔥 INDICADOR DE SENHA (NOVA PARTE)
                  const SizedBox(height: 6),

                  AnimatedBuilder(
                    animation: senhaController,
                    builder: (context, _) {
                      final senha = senhaController.text;

                      final temNumero = RegExp(r'[0-9]').hasMatch(senha);
                      final temMinimo = senha.length >= 6;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "A senha deve conter:",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "• Mínimo 6 caracteres",
                            style: TextStyle(
                              color: temMinimo ? Colors.green : Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),

                          Text(
                            "• Pelo menos 1 número",
                            style: TextStyle(
                              color: temNumero ? Colors.green : Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 50,
                            ),
                          ),
                          child: const Text("Cadastrar"),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? errorMessage = await AuthService().register(
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
  }
}