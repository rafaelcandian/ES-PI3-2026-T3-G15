import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/widgets/bottom_nav_bar.dart';
import 'package:mescla_invest/widgets/app_bar_padrao.dart';
import 'package:mescla_invest/screens/startups/startup_card.dart';
import 'package:mescla_invest/screens/startups/startup_data.dart';
import 'package:mescla_invest/services/startup_service.dart'; // Import the service
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../auth/app_theme.dart';
class CatalogoStartupsPage extends StatefulWidget {
  const CatalogoStartupsPage({super.key});

  @override
  State<CatalogoStartupsPage> createState() => _CatalogoStartupsPageState();
}

class _CatalogoStartupsPageState extends State<CatalogoStartupsPage> {
  //final List<String> _filters = ['Todas', 'Nova', 'Operação', 'Expansão', 'Destaque'];
  final List<String> _filters = ['Todas', 'Varejo', 'Bancário', 'Logística', 'Agronegócio', 'Supermercado'];
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
      appBar: const AppBarPadrao(titulo: 'Catálogo de Startups'),

      // ===================== BODY =====================
      backgroundColor: const Color(0xFF070A1E),
      body: CustomScrollView(
        slivers: [
          // Título e descrição
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 14),
                  _HeaderEyebrow(text: 'STAARTUPS DISPONÍVEIS'),
                  SizedBox(height: 14),
          
                  const Text(
                    'Oportunidades exclusivas de investimento em equity através de ativos digitais fracionados.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB0B8D1),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ),

          // Filtros
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              
              child: SizedBox(
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
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),

          // Lista de startups
          SliverToBoxAdapter(
            
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

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: List.generate(
                      filteredStartups.length,
                      (index) {
                        final startup = filteredStartups[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: index == filteredStartups.length - 1 ? 80 : 32),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/detalhes',
                                arguments: startup,
                              );
                            },
                            child: StartupCard(data: startup, onDetailsTap: () {  },),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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



class _HeaderEyebrow extends StatelessWidget {
  final String text;

  const _HeaderEyebrow({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.destaque,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.destaque,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
