import 'package:flutter/material.dart';
import 'package:mescla_invest/widgets/bottom_nav_bar.dart';
import 'package:mescla_invest/screens/startups/startup_card.dart';
import 'package:mescla_invest/screens/startups/startup_data.dart';


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
                itemCount: StartupCatalogPage.startups.length,
                itemBuilder: (context, index) {
                  final startup = StartupCatalogPage.startups[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, 
                      '/detalhes'
                      , arguments: startup);
                    },
                    child: StartupCard(data: startup),
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

class StartupCatalogPage extends StatelessWidget {
  const StartupCatalogPage({super.key});

  static final List<StartupData> startups = [
    StartupData(
      title: 'NeuroPulse AI',
      subtitle: 'Análise preditiva para saúde neurológica.',
      tag: 'EXPANSÃO',
      equity: '12%',
      tokens: '4.500',
      tokenValue: 'R\$ 250,00',
      progress: 0.75,
      goal: 'R\$ 2.5M',
      image: 'https://images.unsplash.com/photo-1518770660439-4636190af475',
    ),
    StartupData(
      title: 'VerdeSphere',
      subtitle: 'Vertical farming automatizada.',
      tag: 'NOVA',
      equity: '8.5%',
      tokens: '1.200',
      tokenValue: 'R\$ 1.150,00',
      progress: 0.20,
      goal: 'R\$ 1.2M',
      image: 'https://images.unsplash.com/photo-1515378791036-0648a3ef77b2',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mescla Invest')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: StartupCatalogPage.startups.length,
        itemBuilder: (context, index) {
          return StartupCard(data: StartupCatalogPage.startups[index]);
        },
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}