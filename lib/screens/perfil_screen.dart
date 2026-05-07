import 'package:flutter/material.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF070A1E),
        title: const Text("Meu Perfil"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Exibição de dados do perfil
            CircleAvatar(radius: 40, backgroundImage: NetworkImage('https://via.placeholder.com/150')),
            const SizedBox(height: 16),
            Text('Nome: Guilherme Moraes', style: TextStyle(fontSize: 20)),
            Text('E-mail: guilherme@example.com', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            // Opções para alterar dados
            ElevatedButton(
              onPressed: () {
                // Ação para alterar dados pessoais
              },
              child: Text('Alterar Dados'),
            ),
            const SizedBox(height: 16),
            // Opção para habilitar MFA
            ElevatedButton(
              onPressed: () {
                // Ação para habilitar MFA
              },
              child: Text('Habilitar Autenticação Multifatorial (MFA)'),
            ),
          ],
        ),
      ),
    );
  }
}