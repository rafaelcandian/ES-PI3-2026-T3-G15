import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/widgets/bottom_nav_bar.dart';
import 'package:mescla_invest/screens/startups/startup_card.dart';
import 'package:mescla_invest/screens/startups/startup_data.dart';
import 'package:mescla_invest/services/startup_service.dart'; // Import the service
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class CatalogoStartupsPage extends StatefulWidget {
  const CatalogoStartupsPage({super.key});

  @override
  State<CatalogoStartupsPage> createState() => _CatalogoStartupsPageState();
}

class _CatalogoStartupsPageState extends State<CatalogoStartupsPage> {
  final List<String> _filters = ['Todas', 'Nova', 'Operação', 'Expansão', 'Destaque'];
  String _selectedFilter = 'Todas';
  final StartupService _startupService = StartupService(); // Initialize service

  List<StartupData> applyFilter(List<StartupData> startups) {
    if (_selectedFilter == 'Todas') return startups;
    return startups
        .where((startup) =>
            startup.tag.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      // ===================== APPBAR =====================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleSpacing: 0,

        title: Row(
          children: [

            // avatar usuário
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
              child: Text(
                'MESCLA INVEST',
                style: TextStyle(
                  letterSpacing: 1.2,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // notificações
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2555),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.notifications_none,
                  color: Colors.white, size: 24),
            ),

            // ===================== LOGOUT =====================
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2555),
                borderRadius: BorderRadius.circular(50),
              ),
              child: IconButton(
                icon: const Icon(Icons.logout,
                    color: Colors.white, size: 22),

                onPressed: () async {

                  // 🔐 desloga Firebase
                  await FirebaseAuth.instance.signOut();

                  // 🔁 limpa navegação e volta pro login
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ===================== BODY =====================
      backgroundColor: const Color(0xFF070A1E),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 12),

            const Text(
              'Catálogo de Startups',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Oportunidades exclusivas de investimento em equity através de ativos digitais fracionados.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFB0B8D1),
              ),
            ),

            const SizedBox(height: 22),

            // filtros
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 12),
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

            // lista
            Expanded(
              child: StreamBuilder<List<StartupData>>(
                stream: _startupService.getStartups(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}', style: TextStyle(color: Colors.white)));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Nenhuma startup encontrada', style: TextStyle(color: Colors.white)));
                  }

                  final filteredStartups = applyFilter(snapshot.data!);

                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: filteredStartups.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final startup = filteredStartups[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/detalhes',
                            arguments: startup,
                          );
                        },
                        child: StartupCard(data: startup),
                      );
                    },
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


// ===================== FILTER CHIP =====================
class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const FilterChipWidget({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFC53D)
              : const Color(0xFF161D44),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                selected ? const Color(0xFF0F1749) : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}



