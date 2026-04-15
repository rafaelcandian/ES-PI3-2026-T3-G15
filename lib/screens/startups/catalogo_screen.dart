import 'package:flutter/material.dart';
import 'package:mescla_invest/widgets/bottom_nav_bar.dart';
import 'package:mescla_invest/screens/startups/startup_card.dart';
import 'package:mescla_invest/screens/startups/startup_data.dart';


class CatalogoStartupsPage extends StatefulWidget {
  const CatalogoStartupsPage({super.key});

  @override
  State<CatalogoStartupsPage> createState() => _CatalogoStartupsPageState();
}

class _CatalogoStartupsPageState extends State<CatalogoStartupsPage> {
  final List<String> _filters = ['Todas', 'Nova', 'Operação', 'Expansão', 'Destaque'];
  String _selectedFilter = 'Todas';

  List<StartupData> applyFilter(List<StartupData> startups) {
    if (_selectedFilter == 'Todas') return startups;
    return startups
        .where((startup) => startup.tag.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF182051),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text('MESCLA INVEST', style: TextStyle(letterSpacing: 1.2, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2555),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.notifications_none, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF070A1E),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text('Catálogo de Startups', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Manrope')),
            const SizedBox(height: 10),
            const Text(
              'Oportunidades exclusivas de investimento em equity através de ativos digitais fracionados.',
              style: TextStyle(fontSize: 14, color: Color(0xFFB0B8D1)),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final label = _filters[index];
                  return FilterChipWidget(
                    label: label,
                    selected: _selectedFilter == label,
                    onTap: () {
                      setState(() {
                        _selectedFilter = label;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: applyFilter(StartupCatalogPage.startups).length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final startup = applyFilter(StartupCatalogPage.startups)[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/detalhes', arguments: startup);
                    },
                    child: StartupCard(data: startup),
                  );
                },
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const FilterChipWidget({super.key, required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFC53D) : const Color(0xFF161D44),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF0F1749) : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
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