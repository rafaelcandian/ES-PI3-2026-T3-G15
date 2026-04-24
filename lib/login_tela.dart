import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'cadastro_tela.dart';
import 'recuperacaosenha_tela.dart';
import 'catalogo_tela.dart';

class LoginTela extends StatefulWidget {
  const LoginTela({super.key});

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController senhaController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor:
                      AppColors.destaque,
                  child: Icon(
                    Icons.monetization_on,
                    size: 50,
                    color: AppColors.branco,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "MesclaInvest",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.destaque,
                  ),
                ),

                const SizedBox(height: 30),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const TextField(),

                      TextFormField(
                        controller:
                            emailController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'E-mail',
                          hintText:
                              'seu@exemplo.com',
                        ),
                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .isEmpty ||
                              !value.contains(
                                '@',
                              )) {
                            return 'Por favor, insira um e-mail válido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      TextFormField(
                        controller:
                            senhaController,
                        obscureText:
                            true,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Senha',
                        ),
                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .isEmpty) {
                            return 'Por favor, insira sua senha';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      _isLoading
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<
                                    Color
                                  >(
                                AppColors
                                    .destaque,
                              ),
                            )
                          : ElevatedButton(
                              onPressed:
                                  _submitLogin,
                              child:
                                  const Text(
                                "Entrar",
                                style:
                                    TextStyle(
                                  fontSize:
                                      16,
                                ),
                              ),
                            ),

                      const SizedBox(
                        height: 20,
                      ),

                      TextButton(
                        onPressed:
                            _onForgotPassword,
                        child:
                            const Text(
                          'Esqueci minha senha',
                        ),
                      ),

                      TextButton(
                        onPressed:
                            _onCreateAccount,
                        child:
                            const Text(
                          'Criar uma conta',
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

  void _submitLogin() {
    if (_formKey.currentState!
        .validate()) {
      setState(() {
        _isLoading = true;
      });

      Future.delayed(
        const Duration(seconds: 2),
        () {
          setState(() {
            _isLoading = false;
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      const CatalogoStartupsPage(),
            ),
          );
        },
      );
    }
  }

  void _onForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                const RecuperacaoSenhaTela(),
      ),
    );
  }

  void _onCreateAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                const CadastroTela(),
      ),
    );
  }
}