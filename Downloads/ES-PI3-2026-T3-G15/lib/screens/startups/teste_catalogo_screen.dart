import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MesclaInvestApp());
}

class MesclaInvestApp extends StatelessWidget {
  const MesclaInvestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mescla Invest',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070A1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3D64FF),
          secondary: Color(0xFFFFC53D),
          surface: Color(0xFF101730),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFB0B8D1)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF8B97B8)),
        ),
      ),
      home: const StartupCatalogPage(),
    );
  }
}

class StartupCatalogPage extends StatefulWidget {
  const StartupCatalogPage({super.key});

  @override
  State<StartupCatalogPage> createState() => _StartupCatalogPageState();
}

class _StartupCatalogPageState extends State<StartupCatalogPage> {
  late Future<List<StartupCardData>> _startupFuture;
  final List<String> _filters = ['Todas', 'Nova', 'Operação', 'Expansão', 'Destaque'];
  String _selectedFilter = 'Todas';

  @override
  void initState() {
    super.initState();
    _startupFuture = loadStartupData();
  }

  Future<List<StartupCardData>> loadStartupData() async {
    final jsonString = await rootBundle.loadString('assets/startups.json');
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((item) => StartupCardData.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  List<StartupCardData> applyFilter(List<StartupCardData> startups) {
    if (_selectedFilter == 'Todas') return startups;
    if (_selectedFilter == 'Destaque') {
      return startups.where((startup) => startup.featured).toList();
    }
    return startups
        .where((startup) => startup.tag.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('MESCLA INVEST', style: TextStyle(letterSpacing: 1.2, fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  
                ],
              ),
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text('Catálogo de Startups', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white,fontFamily: 'Manrope')),
            const SizedBox(height: 10),
            Text(
              'Oportunidades exclusivas de investimento em equity através de ativos digitais fracionados.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
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
              child: FutureBuilder<List<StartupCardData>>(
                future: _startupFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro ao carregar startups', style: theme.textTheme.bodyLarge));
                  }
                  final startups = applyFilter(snapshot.data ?? []);
                  if (startups.isEmpty) {
                    return Center(
                      child: Text('Nenhuma startup encontrada para este filtro.', style: theme.textTheme.bodyLarge),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: startups.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return StartupCard(data: startups[index]);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigationBarSection(),
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

class StartupCardData {
  final String title;
  final String subtitle;
  final String tag;
  final String equityLabel;
  final String tokens;
  final String tokenValue;
  final double fundingProgress;
  final String goalLabel;
  final String image;
  final bool featured;

  const StartupCardData({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.equityLabel,
    required this.tokens,
    required this.tokenValue,
    required this.fundingProgress,
    required this.goalLabel,
    required this.image,
    required this.featured,
  });

  factory StartupCardData.fromJson(Map<String, dynamic> json) {
    return StartupCardData(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      tag: json['tag'] as String,
      equityLabel: json['equityLabel'] as String,
      tokens: json['tokens'] as String,
      tokenValue: json['tokenValue'] as String,
      fundingProgress: (json['fundingProgress'] as num).toDouble(),
      goalLabel: json['goalLabel'] as String,
      image: json['image'] as String,
      featured: json['featured'] as bool,
    );
  }
}

class StartupCard extends StatelessWidget {
  final StartupCardData data;

  const StartupCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101731),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(data.image, fit: BoxFit.cover),
                  Container(color: Colors.black.withOpacity(0.25)),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E3B7C),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(data.tag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF050A1D).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(data.equityLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFFD57E))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                Text(data.subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF9CADDD), height: 1.5)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _InfoItem(label: 'Tokens disponíveis', value: data.tokens)),
                    Expanded(child: _InfoItem(label: 'Valor do token', value: data.tokenValue)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Captação: ${(data.fundingProgress * 100).round()}%', style: const TextStyle(fontSize: 12, color: Color(0xFF7D91C2), fontWeight: FontWeight.w600)),
                    Text(data.goalLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF9CADDD), fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: data.fundingProgress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF1B2348),
                    color: const Color(0xFFFFC53D),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC53D),
                          foregroundColor: const Color(0xFF0F1749),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: const Text('Ver detalhes →', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: Color(0xFF5F7BC6), letterSpacing: 0.6, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class BottomNavigationBarSection extends StatelessWidget {
  const BottomNavigationBarSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: const BoxDecoration(
        color: Color(0xFF090E25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.only(top: 12, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          BottomNavItem(icon: Icons.home_outlined, label: 'Home'),
          BottomNavItem(icon: Icons.rocket_launch_outlined, label: 'Startups', selected: true),
          BottomNavItem(icon: Icons.wallet_outlined, label: 'Wallet'),
          BottomNavItem(icon: Icons.bar_chart_outlined, label: 'Dashboard'),
          BottomNavItem(icon: Icons.person_outline, label: 'Perfil'),
        ],
      ),
    );
  }
}

class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const BottomNavItem({super.key, required this.icon, required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFFFC53D) : const Color(0xFF8FA0CE);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }
}
