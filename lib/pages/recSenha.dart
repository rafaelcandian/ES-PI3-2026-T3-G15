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
          TextField(
            controller: email,
            style: TextStyle(color: Colors.black),
            cursorColor: Colors.black,
            decoration: const InputDecoration(
              labelText: "E-mail",
            ),
          ),
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