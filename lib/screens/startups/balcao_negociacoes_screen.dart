import 'package:flutter/material.dart';

class BalcaoNegociacoesPage extends StatelessWidget {
  const BalcaoNegociacoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF070A1E),
        title: const Text("Balcão de Negociações"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Exibição de tokens disponíveis para negociação
            Text('Tokens Disponíveis para Negociação: 500', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            // Exibição de ofertas de compra e venda
            Text('Ofertas Ativas:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView(
                children: [
                  ListTile(title: Text('Compra de 100 Tokens - R\$ 25,000')),
                  ListTile(title: Text('Venda de 50 Tokens - R\$ 12,500')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Botões de ação
            ElevatedButton(
              onPressed: () {
                // Ação para registrar uma nova oferta
              },
              child: Text('Registrar Oferta de Compra'),
            ),
            ElevatedButton(
              onPressed: () {
                // Ação para registrar uma nova oferta de venda
              },
              child: Text('Registrar Oferta de Venda'),
            ),
          ],
        ),
      ),
    );
  }
}