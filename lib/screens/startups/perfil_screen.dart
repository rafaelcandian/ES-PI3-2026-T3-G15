import 'package:flutter/material.dart';
import 'package:mescla_invest/widgets/bottom_nav_bar.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                bottom: 24,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(),
                  SizedBox(height: 22),

                  _ProfileCard(),
                  SizedBox(height: 18),

                  _AppearanceSection(),
                  SizedBox(height: 18),

                  _SecuritySection(),
                  SizedBox(height: 18),

                  _NotificationsSection(),
                  SizedBox(height: 18),

                  _PrivacySection(),
                  SizedBox(height: 22),

                  _AccountActions(),
                ],
              ),
            ),
          ),

          const BottomNavBar(selectedIndex: 3),
        ],
      ),
    );
  }
}

class _C {
  static const bg           = Color(0xFF020818);
  static const surface      = Color(0xFF0B1230);
  static const surfaceRaised = Color(0xFF0F1840);
  static const card         = Color(0xFF0D1535);
  static const gold         = Color(0xFFEFCD57);
  static const goldDim      = Color(0xFFB89A2E);
  static const goldGlow     = Color(0x22EFCD57);
  static const goldBorder   = Color(0x33EFCD57);
  static const white        = Colors.white;
  static const white70      = Colors.white70;
  static const white50      = Color(0x80FFFFFF);
  static const white30      = Color(0x4DFFFFFF);
  static const white12      = Color(0x1FFFFFFF);
  static const white06      = Color(0x0FFFFFFF);
  static const blue         = Color(0xFF1A3A8F);
}
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Perfil',
            style: TextStyle(
              fontFamily: 'Syne',
              color: _C.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.white12),
          ),
          child: const Icon(
            Icons.settings_outlined,
            color: _C.gold,
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.gold, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: _C.gold.withOpacity(0.16),
                      blurRadius: 26,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: _C.card,
                  child: const Icon(
                    Icons.person_rounded,
                    color: _C.white70,
                    size: 48,
                  ),
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: _C.gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: _C.surface,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Text(
            'Guilherme Moraes',
            style: TextStyle(
              color: _C.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'guilherme@example.com',
            style: TextStyle(
              color: _C.white50,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            '+55 19 99999-9999',
            style: TextStyle(
              color: _C.white30,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.gold,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {},
              child: const Text(
                'Editar perfil',
                style: TextStyle(
                  color: _C.surface,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Aparência',
      icon: Icons.palette_outlined,
      child: Column(
        children: [
          Row(
            children: const [
              _ThemePill(label: 'Light', active: false),
              SizedBox(width: 8),
              _ThemePill(label: 'Dark', active: true),
              SizedBox(width: 8),
              _ThemePill(label: 'Auto', active: false),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 76,
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _C.white06),
                  ),
                  child: const Icon(
                    Icons.dark_mode_outlined,
                    color: _C.white30,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 76,
                  decoration: BoxDecoration(
                    color: _C.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _C.gold.withOpacity(0.35)),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: _C.gold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecuritySection extends StatelessWidget {
  const _SecuritySection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Segurança',
      icon: Icons.shield_outlined,
      child: Column(
        children: const [
          _ToggleRow(
            title: '2FA ativo',
            subtitle: 'Autenticação em 2 fatores',
            active: true,
          ),
          SizedBox(height: 10),
          _ActionRow(title: 'Alterar senha'),
          _ActionRow(title: 'Redefinir senha'),
          _ActionRow(title: 'Logout de todos os dispositivos', danger: true),
        ],
      ),
    );
  }
}

class _NotificationsSection extends StatelessWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Notificações',
      icon: Icons.notifications_outlined,
      child: Column(
        children: const [
          _CheckRow(title: 'Valorização de tokens', checked: true),
          _CheckRow(title: 'Alertas de compra e venda', checked: true),
          _CheckRow(title: 'Notícias das startups', checked: false),
          _CheckRow(title: 'Avisos de perguntas respondidas', checked: true),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Privacidade',
      icon: Icons.lock_outline_rounded,
      child: Column(
        children: const [
          _ActionRow(title: 'Gerenciamento de dados'),
          _ActionRow(title: 'Visualizar CPF e telefone'),
          _ToggleRow(
            title: 'Ocultar saldo',
            subtitle: 'Esconde valores sensíveis na tela',
            active: true,
          ),
          _ActionRow(title: 'Dispositivos conectados'),
        ],
      ),
    );
  }
}

class _AccountActions extends StatelessWidget {
  const _AccountActions();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _C.white12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {},
              icon: const Icon(
                Icons.logout_rounded,
                color: _C.white70,
                size: 18,
              ),
              label: const Text(
                'Sair da conta',
                style: TextStyle(
                  color: _C.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: () {},
            child: const Text(
              'Excluir conta',
              style: TextStyle(
                color: _C.white50,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'MesclaInvest • v1.0.0',
            style: TextStyle(
              color: _C.gold,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget child;

  const _SectionCard({
    this.title,
    this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.white12, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: _C.gold.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(icon, color: _C.gold, size: 17),
                const SizedBox(width: 8),
                Text(
                  title!,
                  style: const TextStyle(
                    color: _C.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

class _ThemePill extends StatelessWidget {
  final String label;
  final bool active;

  const _ThemePill({
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: active ? _C.gold : _C.white06,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? _C.surface : _C.white50,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String title;
  final bool danger;

  const _ActionRow({
    required this.title,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _C.surface.withOpacity(0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.white06),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: danger ? _C.gold : _C.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: _C.white30,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool active;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _C.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _C.white30,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 24,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: active ? _C.gold : _C.white12,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Align(
            alignment: active ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: active ? _C.surface : _C.white50,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String title;
  final bool checked;

  const _CheckRow({
    required this.title,
    required this.checked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _C.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(
            checked
                ? Icons.check_box_rounded
                : Icons.check_box_outline_blank_rounded,
            color: checked ? _C.gold : _C.white30,
            size: 18,
          ),
        ],
      ),
    );
  }
}