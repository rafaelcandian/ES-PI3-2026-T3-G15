import 'package:flutter/material.dart';

class RecuperarSenhaPage extends StatelessWidget {
  const RecuperarSenhaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10184e),
      appBar: AppBar(
        title: const Text('Recuperação de Senha'),
        backgroundColor: const Color(0xFF10184e),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center( // 🔥 centraliza melhor
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "Recuperar Senha",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Enviaremos os passos para o seu e-mail.",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                TextFormField( // 🔥 melhor que TextField
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'E-mail',
                    hintText: 'exemplo@invest.com.br',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
  onPressed: () {
    // Lógica para enviar o e-mail de recuperação de senha
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("E-mail de recuperação enviado!")),
    );
    Navigator.pop(context);
  },
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
                  child: const Text(
                    "Enviar código",
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 20),

                TextButton(
  onPressed: () {
    Navigator.pop(context);
  },
                  child: const Text(
                    'Não recebeu nada? Tente outro e-mail',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}