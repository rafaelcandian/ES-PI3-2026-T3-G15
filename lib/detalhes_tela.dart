import 'package:flutter/material.dart';

class DetalhesStartupPage extends StatelessWidget {
  const DetalhesStartupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10184e),
      appBar: AppBar(
        title: const Text('Detalhes da Oferta'),
        backgroundColor: const Color(0xFF10184e),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Voltar para a tela anterior
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Image.asset('assets/pitch_deck_image.png'), // Coloque a imagem do pitch
            const SizedBox(height: 20),
            const Text(
              "SolarStream Tech",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
            ),
            const SizedBox(height: 10),
            const Text(
              "Energia Limpa, SaaS B2B, Série A",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              "Valor do Token: R\$ 1.250,00",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "Meta alcançada: 82%",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              "Sumário Executivo",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
            ),
            const SizedBox(height: 10),
            const Text(
              "A SolarStream Tech está revolucionando a distribuição de energia solar por meio de algoritmos de otimização em tempo real.",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              "Crescimento: +140% aa",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "Clientes: 120+",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                primary: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Comprar tokens'),
            ),
          ],
        ),
      ),
    );
  }
}