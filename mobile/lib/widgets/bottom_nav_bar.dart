import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mescla_invest/themes/app_theme.dart';

class BottomNavBar extends StatefulWidget {
  final int selectedIndex;

  const BottomNavBar({
    super.key,
    this.selectedIndex = 0,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with TickerProviderStateMixin {
  late int _selectedIndex;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnims;
  late List<Animation<double>> _glowAnims;

  static const List<_NavItem> _items = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Início',
      route: '/catalogo',
    ),
    _NavItem(
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
      label: 'Balcão',
      route: '/balcao',
    ),
    _NavItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      label: 'Carteira',
      route: '/carteira',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Perfil',
      route: '/perfil',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _selectedIndex = widget.selectedIndex.clamp(0, _items.length - 1);

    _controllers = List.generate(
      _items.length,
          (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      ),
    );

    _scaleAnims = _controllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 1.15,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutBack,
        ),
      );
    }).toList();

    _glowAnims = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );
    }).toList();

    _controllers[_selectedIndex].forward();
  }

  @override
  void didUpdateWidget(covariant BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newIndex = widget.selectedIndex.clamp(0, _items.length - 1);

    if (newIndex != _selectedIndex) {
      _controllers[_selectedIndex].reverse();
      _selectedIndex = newIndex;
      _controllers[_selectedIndex].forward();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _onTap(int index) {
    if (index == _selectedIndex) return;

    HapticFeedback.lightImpact();

    _controllers[_selectedIndex].reverse();

    setState(() {
      _selectedIndex = index;
    });

    _controllers[index].forward();

    Navigator.pushReplacementNamed(
      context,
      _items[index].route,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.bordaClara,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.destaque.withValues(alpha: 0.06),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_items.length, _buildItem),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index) {
    final bool isSelected = _selectedIndex == index;
    final item = _items[index];

    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 82,
        height: 80,
        child: Center(
          child: AnimatedBuilder(
            animation: _controllers[index],
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: _scaleAnims[index].value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isSelected)
                          Opacity(
                            opacity: _glowAnims[index].value * 0.35,
                            child: Container(
                              width: 52,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.destaque.withValues(
                                      alpha: 0.8,
                                    ),
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          width: isSelected ? 52 : 44,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.destaque
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected
                              ? AppColors.card
                              : AppColors.textoMuitoFraco,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.destaque
                          : AppColors.textoMuitoFraco,
                      fontSize: 10,
                      fontWeight:
                      isSelected ? FontWeight.w800 : FontWeight.w400,
                      letterSpacing: isSelected ? 0.4 : 0,
                    ),
                    child: Text(item.label),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}