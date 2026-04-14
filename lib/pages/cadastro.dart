import 'package:flutter/material.dart';
import '../services/autenticacao.dart';

class RegisterPage extends StatelessWidget {
  final nome = TextEditingController();
  final email = TextEditingController();
  final cpf = TextEditingController();
  final telefone = TextEditingController();
  final senha = TextEditingController();

  final auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(controller: nome),
          TextField(controller: email),
          TextField(controller: cpf),
          TextField(controller: telefone),
          TextField(controller: senha),

          ElevatedButton(
            onPressed: () async {
              var erro = await auth.register(
                nome: nome.text,
                email: email.text,
                cpf: cpf.text,
                telefone: telefone.text,
                senha: senha.text,
              );

              print(erro ?? "Cadastro OK");
            },
            child: Text("Cadastrar"),
          )
        ],
      ),
    );
  }
}