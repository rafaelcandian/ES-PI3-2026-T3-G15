import 'package:flutter/material.dart';
import '../services/autenticacao.dart';

class LoginPage extends StatelessWidget {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(controller: emailController),
          TextField(controller: senhaController),
          ElevatedButton(
            onPressed: () async {
              var erro = await auth.login(
                emailController.text,
                senhaController.text,
              );

              print(erro ?? "Login OK");
            },
            child: Text("Login"),
          )
        ],
      ),
    );
  }
}