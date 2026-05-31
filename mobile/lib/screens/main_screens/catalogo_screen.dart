/* Victória Nobre - 25016398 */
/* Guilherme Henrique Moreira - 25006702 */

import 'package:flutter/material.dart';

import 'package:mescla_invest/widgets/shared/page_header.dart';
import 'package:mescla_invest/widgets/app_bar_padrao.dart';
import 'package:mescla_invest/widgets/bottom_nav_bar.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';

import 'package:mescla_invest/screens/startups/startup_card.dart';
import 'package:mescla_invest/screens/startups/startup_data.dart';
import 'package:mescla_invest/services/startup_service.dart';

import '../../themes/app_theme.dart';

/* Página de Catálogo: Atua como o Marketplace primário do app.
   A implementação utiliza StreamBuilder para reagir a mudanças no banco de dados 
   (Firestore) sem necessidade de Refresh manual, seguindo o padrão Reactive Programming. */
class CatalogoStartupsPage extends StatefulWidget {
  const CatalogoStartupsPage({super.key});

  @override
  State<CatalogoStartupsPage> createState() => _CatalogoStartupsPageState();
}

class _CatalogoStartupsPageState extends State<CatalogoStartupsPage> {
  final StartupService _startupService = StartupService();

  /* Filtros pré-definidos para categorização de startups, visando facilitar a UX do investidor. */
  final List<String> _areaFilters = [
    'Todas',
    'Varejo',
    'Bancário',
    'Logística',
    'Agronegócio',
    'Supermercado',
  ];

  final List<String> _stageFilters = [
    'Todos',
    'Em operação',
    'Nova',
    'Em expansão',
  ];

  String _selectedAreaFilter = 'Todas';
  String _selectedStageFilter = 'Todos';

  bool _areaFilterOpen = false;
  bool _stageFilterOpen = false;

  /* Aplica filtros de área e estágio para refinar a listagem de oportunidades. */
  List<StartupData> _applyFilters(List<StartupData> startups) {
    return startups.where((startup) {
      final areaMatch =
          _selectedAreaFilter == 'Todas' ||
              startup.tag.toLowerCase().trim() ==
                  _selectedAreaFilter.toLowerCase().trim();

      final stageMatch =
          _selectedStageFilter == 'Todos' ||
              startup.stage.toLowerCase().trim() ==
                  _selectedStageFilter.toLowerCase().trim();

      return areaMatch && stageMatch;
    }).toList();
  }

  /* Transição para a tela de informações detalhadas da startup selecionada. */
  void _abrirDetalhes(StartupData startup) {
    Navigator.pushNamed(context, '/detalhes', arguments: startup);
  }

  String _mensagemFiltroVazio() {
    if (_selectedAreaFilter != 'Todas' && _selectedStageFilter != 'Todos') {
      return 'Não encontramos startups da área "$_selectedAreaFilter" no estágio "$_selectedStageFilter".';
    }

    if (_selectedAreaFilter != 'Todas') {
      return 'Não encontramos startups na categoria "$_selectedAreaFilter".';
    }

    if (_selectedStageFilter != 'Todos') {
      return 'Não encontramos startups no estágio "$_selectedStageFilter".';
    }

    return 'Nenhuma startup encontrada com os filtros selecionados.';
  }

  void _toggleAreaFilter() {
    setState(() {
      _areaFilterOpen = !_areaFilterOpen;

      if (_areaFilterOpen) {
        _stageFilterOpen = false;
      }
    });
  }

  void _toggleStageFilter() {
    setState(() {
      _stageFilterOpen = !_stageFilterOpen;

      if (_stageFilterOpen) {
        _areaFilterOpen = false;
      }
    });
  }

  void _selectAreaFilter(String value) {
    setState(() {
      _selectedAreaFilter = value;
      _areaFilterOpen = false;
    });
  }

  void _selectStageFilter(String value) {
    setState(() {
      _selectedStageFilter = value;
      _stageFilterOpen = false;
    });
  }

  void _limparFiltros() {
    setState(() {
      _selectedAreaFilter = 'Todas';
      _selectedStageFilter = 'Todos';
      _areaFilterOpen = false;
      _stageFilterOpen = false;
    });
  }

  bool get _temFiltroAtivo {
    return _selectedAreaFilter != 'Todas' || _selectedStageFilter != 'Todos';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      backgroundColor: AppColors.fundo,
      appBar: const AppBarPadrao(titulo: ''),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 0),
      body: Stack(
        children: [
          const _AtmosphericBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: PageHeader(
                    title: 'Catálogo de Startups',
                    subtitle:
                        'Oportunidades exclusivas de investimento em equity através de ativos digitais fracionados.',
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ModernFilterPanel(
                    selectedArea: _selectedAreaFilter,
                    selectedStage: _selectedStageFilter,
                    areaFilters: _areaFilters,
                    stageFilters: _stageFilters,
                    areaOpen: _areaFilterOpen,
                    stageOpen: _stageFilterOpen,
                    hasActiveFilter: _temFiltroAtivo,
                    onAreaTap: _toggleAreaFilter,
                    onStageTap: _toggleStageFilter,
                    onAreaSelected: _selectAreaFilter,
                    onStageSelected: _selectStageFilter,
                    onClear: _limparFiltros,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 22)),
              SliverToBoxAdapter(
                /* Stream que monitora em tempo real a coleção de startups no Firestore. */
                child: StreamBuilder<List<StartupData>>(
                  stream: _startupService.getStartups(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.destaque,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                        child: _EmptyStateCard(
                          icon: Icons.error_outline_rounded,
                          title: 'Erro ao carregar startups',
                          message: 'Não foi possível carregar as informações das startups. Verifique sua conexão e tente novamente.',
                        ),
                      );
                    }

                    final startups = snapshot.data ?? [];
                    final filteredStartups = _applyFilters(startups);

                    if (startups.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.fromLTRB(20, 60, 20, 0),
                        child: _EmptyStateCard(
                          icon: Icons.apartment_rounded,
                          title: 'Nenhuma startup encontrada',
                          message:
                          'Ainda não existem startups cadastradas no Firebase.',
                        ),
                      );
                    }

                    if (filteredStartups.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                        child: _EmptyStateCard(
                          icon: Icons.filter_alt_off_rounded,
                          title: 'Nenhuma startup nesse filtro',
                          message: _mensagemFiltroVazio(),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: List.generate(filteredStartups.length, (
                            index,
                            ) {
                          final startup = filteredStartups[index];

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == filteredStartups.length - 1
                                  ? 32
                                  : 28,
                            ),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _abrirDetalhes(startup),
                              child: StartupCard(
                                data: startup,
                                onDetailsTap: () => _abrirDetalhes(startup),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===================== PAINEL DE FILTROS MODERNO =====================

/* Componente de filtragem interativo com suporte a múltiplas categorias. */
class _ModernFilterPanel extends StatelessWidget {
  final String selectedArea;
  final String selectedStage;

  final List<String> areaFilters;
  final List<String> stageFilters;

  final bool areaOpen;
  final bool stageOpen;
  final bool hasActiveFilter;

  final VoidCallback onAreaTap;
  final VoidCallback onStageTap;
  final ValueChanged<String> onAreaSelected;
  final ValueChanged<String> onStageSelected;
  final VoidCallback onClear;

  const _ModernFilterPanel({
    required this.selectedArea,
    required this.selectedStage,
    required this.areaFilters,
    required this.stageFilters,
    required this.areaOpen,
    required this.stageOpen,
    required this.hasActiveFilter,
    required this.onAreaTap,
    required this.onStageTap,
    required this.onAreaSelected,
    required this.onStageSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: premiumCardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: PremiumSectionLabel(text: 'Filtros')),
              if (hasActiveFilter)
                GestureDetector(
                  onTap: onClear,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.campo,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.bordaClara),
                    ),
                    child: const Text(
                      'Limpar',
                      style: TextStyle(
                        color: AppColors.destaque,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FilterSelectorButton(
                  title: 'Área',
                  value: selectedArea,
                  icon: Icons.business_center_outlined,
                  opened: areaOpen,
                  onTap: onAreaTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilterSelectorButton(
                  title: 'Estágio',
                  value: selectedStage,
                  icon: Icons.timeline_rounded,
                  opened: stageOpen,
                  onTap: onStageTap,
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: areaOpen
                ? Padding(
              key: const ValueKey('area-list'),
              padding: const EdgeInsets.only(top: 16),
              child: _FilterOptionsList(
                title: 'Escolha uma área de atuação',
                options: areaFilters,
                selected: selectedArea,
                onSelected: onAreaSelected,
              ),
            )
                : stageOpen
                ? Padding(
              key: const ValueKey('stage-list'),
              padding: const EdgeInsets.only(top: 16),
              child: _FilterOptionsList(
                title: 'Escolha o estágio da startup',
                options: stageFilters,
                selected: selectedStage,
                onSelected: onStageSelected,
              ),
            )
                : const SizedBox.shrink(key: ValueKey('closed-list')),
          ),
        ],
      ),
    );
  }
}

class _FilterSelectorButton extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool opened;
  final VoidCallback onTap;

  const _FilterSelectorButton({
    required this.title,
    required this.value,
    required this.icon,
    required this.opened,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: opened ? AppColors.cardElevado : AppColors.campo,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: opened ? AppColors.bordaDestaque : AppColors.bordaClara,
              width: opened ? 1.1 : 0.8,
            ),
            boxShadow: const [],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.destaque.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.destaque.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(icon, color: AppColors.destaque, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textoMuitoFraco,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textoPrincipal,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: opened ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.destaque,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterOptionsList extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterOptionsList({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: premiumFieldDecoration(radius: 18),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((option) {
              final active = selected == option;

              return _FilterOptionChip(
                label: option,
                active: active,
                onTap: () => onSelected(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _FilterOptionChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterOptionChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.destaque : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? AppColors.destaque : AppColors.bordaClara,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active) ...[
                const Icon(
                  Icons.check_rounded,
                  color: AppColors.fundo,
                  size: 15,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.fundo : AppColors.textoSecundario,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== BACKGROUND =====================

class _AtmosphericBackground extends StatelessWidget {
  const _AtmosphericBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.azul.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 220,
            left: -130,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.destaque.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.roxo.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== EMPTY / ERROR STATE =====================

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: premiumCardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: AppColors.destaque, size: 34),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textoPrincipal,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textoFraco,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
