import 'package:flutter/material.dart';
import 'package:mescla_invest/services/autenticacao.dart';


class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Para controlar o estado de carregamento

  TextEditingController nomeController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController cpfController = TextEditingController();
  TextEditingController telefoneController = TextEditingController();
  TextEditingController senhaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título
            Text(
              "Criar conta",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
              ),
            ),
            SizedBox(height: 20),

            // Formulário de Cadastro
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Nome Completo
                  TextFormField(
                    controller: nomeController,
                    decoration: InputDecoration(
                      labelText: 'Nome Completo',
                      hintText: 'Ex: Roberto Silva',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu nome completo';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),

                  // E-mail
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      hintText: 'nome@exemplo.com',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Por favor, insira um e-mail válido';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),

                  // CPF
                  TextFormField(
                    controller: cpfController,
                    decoration: InputDecoration(
                      labelText: 'CPF',
                      hintText: '000.000.000-00',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu CPF';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),

                  // Telefone
                  TextFormField(
                    controller: telefoneController,
                    decoration: InputDecoration(
                      labelText: 'Telefone',
                      hintText: '(00) 00000-0000',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu telefone';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),

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
                        return 'Por favor, insira uma senha';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

                  // Botão de Cadastro
                  _isLoading
                      ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                        )
                      : ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
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
    );
  }

  // Função para submeter o formulário
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String? errorMessage = await AuthService().register(
        nome: nomeController.text,
        email: emailController.text,
        cpf: cpfController.text,
        telefone: telefoneController.text,
        senha: senhaController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (errorMessage == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cadastro realizado com sucesso!")),
        );
        Navigator.pushReplacementNamed(context, 
        '/login'
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }
}