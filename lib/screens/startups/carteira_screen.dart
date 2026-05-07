import 'package:flutter/material.dart';

class CarteiraPage extends StatelessWidget {
  const CarteiraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF070A1E),
        title: const Text("Minha Carteira"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Exibição de tokens e saldo
            Text('Tokens disponíveis: 4500', style: TextStyle(fontSize: 20)),
            Text('Saldo disponível: R\$ 1,125,000.00', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            // Botão para compra de tokens
            ElevatedButton(
              onPressed: () {
                // Ação para comprar tokens
              },
              child: Text('Comprar Tokens'),
            ),
            const SizedBox(height: 16),
            // Histórico de transações ou outra opção
            Text('Histórico de transações:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // ListView para mostrar transações, com exemplo simples
            Expanded(
              child: ListView(
                children: [
                  ListTile(title: Text('Compra de 100 Tokens - R\$ 25,000')),
                  ListTile(title: Text('Venda de 50 Tokens - R\$ 12,500')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}