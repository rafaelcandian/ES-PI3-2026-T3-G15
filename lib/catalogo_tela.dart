import 'package:flutter/material.dart';

class CatalogoStartupsPage extends StatelessWidget {
  const CatalogoStartupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10184e),
      appBar: AppBar(
        title: const Text('Catálogo de Startups'),
        backgroundColor: const Color(0xFF10184e),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Oportunidades exclusivas de investimento em equity através de ativos digitais fracionados.",
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // 🔥 Scroll horizontal pros filtros
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterButton('Todas'),
                  _buildFilterButton('Nova'),
                  _buildFilterButton('Operação'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Card(
                    color: const Color(0xFF2D2D44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NeuroPulse AI',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Análise preditiva para saúde neurológica em tempo real usando deep learning.',
                            style: TextStyle(color: Colors.white),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Expansão: 12% Equity',
                            style: TextStyle(color: Colors.white),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Tokens disponíveis: 4.500',
                                style: TextStyle(color: Colors.white),
                              ),
                              Text(
                                'Valor do token: R\$ 250,00',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent, // corrigido
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Ver detalhes'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 função pra padronizar botão
  Widget _buildFilterButton(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
        ),
        child: Text(text),
      ),
    );
  }
}