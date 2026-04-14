import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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
      ),
      home: const StartupCatalogPage(),
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
        itemCount: startups.length,
        itemBuilder: (context, index) {
          return StartupCard(data: startups[index]);
        },
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class StartupData {
  final String title;
  final String subtitle;
  final String tag;
  final String equity;
  final String tokens;
  final String tokenValue;
  final double progress;
  final String goal;
  final String image;

  const StartupData({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.equity,
    required this.tokens,
    required this.tokenValue,
    required this.progress,
    required this.goal,
    required this.image,
  });
}

class StartupCard extends StatelessWidget {
  final StartupData data;

  const StartupCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Image.network(data.image, width: 50, fit: BoxFit.cover),
        title: Text(data.title),
        subtitle: Text(data.subtitle),
        trailing: Text(data.equity),
      ),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.rocket), label: 'Startups'),
        BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Wallet'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}