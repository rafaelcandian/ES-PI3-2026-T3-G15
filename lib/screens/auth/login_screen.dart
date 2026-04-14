import 'package:flutter/material.dart';
import 'package:mescla_invest/services/autenticacao.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.orangeAccent,
                  child: const Icon(
                    Icons.monetization_on,
                    size: 50,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                // Título
                const Text(
                  "MesclaInvest",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),

                const SizedBox(height: 30),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          hintText: 'seu@exemplo.com',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              !value.contains('@')) {
                            return 'Insira um e-mail válido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Senha
                      TextFormField(
                        controller: senhaController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Insira sua senha';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Botão
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _submitLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent, // corrigido
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 50,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text("Entrar"),
                            ),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: _onForgotPassword,
                        child: const Text(
                          'Esqueci minha senha',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                      TextButton(
                        onPressed: _onCreateAccount,
                        child: const Text(
                          'Criar uma conta',
                          style: TextStyle(color: Colors.white),
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

  void _submitLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      String? errorMessage = await AuthService()
          .login(emailController.text, senhaController.text);
      setState(() => _isLoading = false);

      if (errorMessage == null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, 
        '/catalogo
        ');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  void _onForgotPassword() {
    Navigator.pushNamed(context, 
    '/recuperacao_senha
    ');
  }

  void _onCreateAccount() {
    Navigator.pushNamed(context, 
    '/cadastro
    ');
  }
}