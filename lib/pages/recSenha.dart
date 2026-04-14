import 'package:flutter/material.dart';
import '../services/autenticacao.dart';

class ForgotPage extends StatelessWidget {
  final email = TextEditingController();
  final auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(controller: email),
          ElevatedButton(
            onPressed: () async {
              var erro = await auth.resetPassword(email.text);
              print(erro ?? "Email enviado!");
            },
            child: Text("Recuperar senha"),
          )
        ],
      ),
    );
  }
}