import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomNavBar extends StatefulWidget {
  final int selectedIndex;

  const BottomNavBar({super.key, this.selectedIndex = 0});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();

  // Criando um getter para acessar _items de fora
  static List<_NavItem> get items => items;
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
      activeIcon: Icons.person,
      label: 'Perfil',
      route: '/perfil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;

    _controllers = List.generate(
      _items.length,
          (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      ),
    );

    _scaleAnims = _controllers
        .map((c) => Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: c, curve: Curves.easeOutBack),
    ))
        .toList();

    _glowAnims = _controllers
        .map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: c, curve: Curves.easeOut),
    ))
        .toList();

    _controllers[_selectedIndex].forward();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTap(int index) {
    if (index == _selectedIndex) return;

    HapticFeedback.lightImpact();

    _controllers[_selectedIndex].reverse();
    setState(() => _selectedIndex = index);
    _controllers[index].forward();

    // Substituindo a tela atual pela nova página ao invés de empilhar
    Navigator.pushReplacementNamed(context, _items[index].route);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1028),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withOpacity(0.07),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.55),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: const Color(0xFFEFCD57).withOpacity(0.06),
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
    );
  }

  Widget _buildItem(int index) {
    final bool isSelected = _selectedIndex == index;
    final item = _items[index];

    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 90,
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
                        // Glow dourado
                        if (isSelected)
                          Opacity(
                            opacity: _glowAnims[index].value * 0.35,
                            child: Container(
                              width: 52,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFFEFCD57),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Pill de fundo animado
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          width: isSelected ? 52 : 44,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEFCD57)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),

                        // Ícone
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected
                              ? const Color(0xFF03081C)
                              : Colors.white30,
                          size: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 5),

                  // Label
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFEFCD57)
                          : Colors.white30,
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