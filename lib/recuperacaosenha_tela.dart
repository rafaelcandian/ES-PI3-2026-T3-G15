import 'package:flutter/material.dart';
import 'app_theme.dart';

class RecuperacaoSenhaTela extends StatelessWidget {
  const RecuperacaoSenhaTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,

      appBar: AppBar(
        title: const Text('Recuperação de Senha'),
        backgroundColor: AppColors.fundo,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Recuperar Senha",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.destaque,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Enviaremos os passos para o seu e-mail.",
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.branco,
                ),
              ),

              const SizedBox(height: 20),

              const TextField(
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  hintText: 'exemplo@invest.com.br',
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {},
                child: const Text(
                  "Enviar código",
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {},
                child: const Text(
                  'Não recebeu nada? Tente outro e-mail',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}