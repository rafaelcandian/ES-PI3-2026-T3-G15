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
          TextField(
            controller: nome,
            style: TextStyle(color: Colors.black),
            cursorColor: Colors.black,
            decoration: const InputDecoration(
              labelText: 'Nome Completo',
            ),
          ),
          TextField(
            controller: email,
            style: TextStyle(color: Colors.black),
            cursorColor: Colors.black,
            decoration: const InputDecoration(
              labelText: 'E-mail',
            ),
          ),
          TextField(
            controller: cpf,
            style: TextStyle(color: Colors.black),
            cursorColor: Colors.black,
            decoration: const InputDecoration(
              labelText: 'CPF',
            ),
          ),
          TextField(
            controller: telefone,
            style: TextStyle(color: Colors.black),
            cursorColor: Colors.black,
            decoration: const InputDecoration(
              labelText: 'Telefone',
            ),
          ),
          TextField(
            controller: senha,
            style: TextStyle(color: Colors.black),
            cursorColor: Colors.black,
            decoration: const InputDecoration(
              labelText: 'Senha',
            ),
            obscureText: true,
          ),

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