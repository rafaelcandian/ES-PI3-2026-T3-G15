import 'package:flutter/material.dart';
import 'app_theme.dart';

class CatalogoStartupsPage extends StatelessWidget {
  const CatalogoStartupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,

      appBar: AppBar(
        title: const Text('Catálogo de Startups'),
        backgroundColor: AppColors.fundo,
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
              style: TextStyle(
                color: AppColors.branco,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Todas'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Nova'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Operação'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Card(
                    color: AppColors.roxo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.only(bottom: 20),

                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NeuroPulse AI',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.branco,
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Análise preditiva para saúde neurológica em tempo real usando deep learning.',
                            style: TextStyle(
                              color: AppColors.branco,
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Expansão: 12% Equity',
                            style: TextStyle(
                              color: AppColors.branco,
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tokens disponíveis: 4.500',
                                style: TextStyle(
                                  color: AppColors.branco,
                                ),
                              ),
                              Text(
                                'Valor do token: R\$ 250,00',
                                style: TextStyle(
                                  color: AppColors.branco,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          ElevatedButton(
                            onPressed: () {},
                            child: const Text(
                              'Ver detalhes',
                            ),
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
}