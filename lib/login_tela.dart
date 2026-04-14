import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFF10184e),
        body: Center(
          child: LoginPage(),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Para controlar o estado de carregamento

  TextEditingController emailController = TextEditingController();
  TextEditingController senhaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Align(
              alignment: Alignment.center,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.orangeAccent,
                child: Icon(
                  Icons.monetization_on,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Título
            Text(
              "MesclaInvest",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
              ),
            ),
            SizedBox(height: 30),

            // Formulário de Login
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // E-mail
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
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Por favor, insira um e-mail válido';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

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
                        return 'Por favor, insira sua senha';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

                  // Botão de Login
                  _isLoading
                      ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                        )
                      : ElevatedButton(
                          onPressed: _submitLogin,
                          style: ElevatedButton.styleFrom(
                            primary: Colors.orangeAccent,
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "Entrar",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                  SizedBox(height: 20),

                  // Link para recuperação de senha
                  TextButton(
                    onPressed: _onForgotPassword,
                    child: Text(
                      'Esqueci minha senha',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  // Link para criação de conta
                  TextButton(
                    onPressed: _onCreateAccount,
                    child: Text(
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
    );
  }

  // Função para submeter o login
  void _submitLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Aqui seria onde você colocaria a lógica de autenticação, por exemplo, com Firebase
      // Simulando um atraso de 2 segundos
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });

        // Aqui você pode verificar as credenciais e navegar para a tela principal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login realizado com sucesso!")),
        );
      });
    }
  }

  // Função para recuperação de senha
  void _onForgotPassword() {
    // Navegar para a tela de recuperação de senha ou exibir um pop-up
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Recuperação de senha não implementada ainda!")),
    );
  }

  // Função para criar uma conta
  void _onCreateAccount() {
    // Navegar para a tela de cadastro
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Tela de cadastro não implementada ainda!")),
    );
  }
}