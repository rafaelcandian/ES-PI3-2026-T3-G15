import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mescla_invest/widgets/bottom_nav_bar.dart';
import 'package:mescla_invest/widgets/app_bar_padrao.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';

import '../../themes/app_theme.dart';
import '../../themes/theme_controller.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  AppAppearanceMode _appearanceMode = ThemeController.appearanceMode.value;

  bool _loading = true;

  String _nome = 'Usuário';
  String _email = '';
  String _telefone = '';
  String _cpf = '';

  String get _appearanceLabel {
    switch (_appearanceMode) {
      case AppAppearanceMode.light:
        return 'Light';
      case AppAppearanceMode.dark:
        return 'Dark';
      case AppAppearanceMode.auto:
        return 'Auto';
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
        return;
      }

      String nome = user.displayName ?? 'Usuário';
      String email = user.email ?? '';
      String telefone = user.phoneNumber ?? '';
      String cpf = '';

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      final data = doc.data();

      if (data != null) {
        nome = data['nome'] ??
            data['name'] ??
            data['displayName'] ??
            nome;

        email = data['email'] ?? email;

        telefone = data['telefone'] ??
            data['phone'] ??
            data['celular'] ??
            telefone;

        cpf = data['cpf'] ?? '';
      }

      if (!mounted) return;

      setState(() {
        _nome = nome.toString().trim().isEmpty ? 'Usuário' : nome.toString();
        _email = email.toString();
        _telefone = telefone.toString();
        _cpf = cpf.toString();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;

      setState(() {
        _nome = user?.displayName ?? 'Usuário';
        _email = user?.email ?? '';
        _telefone = user?.phoneNumber ?? '';
        _cpf = '';
        _loading = false;
      });
    }
  }

  String _mascararCpf(String cpf) {
    final digits = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length != 11) {
      return cpf.isEmpty ? 'Não informado' : cpf;
    }

    return '${digits.substring(0, 3)}.***.***-${digits.substring(9, 11)}';
  }

  String _mascararTelefone(String telefone) {
    final digits = telefone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length < 10) {
      return telefone.isEmpty ? 'Não informado' : telefone;
    }

    final ddd = digits.substring(0, 2);
    final fim = digits.substring(digits.length - 4);

    return '($ddd) *****-$fim';
  }

  void _alterarAparencia(AppAppearanceMode mode) {
    ThemeController.setAppearanceMode(mode);

    setState(() {
      _appearanceMode = mode;
    });

    _showSnackBar(
      'Modo de aparência alterado para $_appearanceLabel.',
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.textoPrincipal,
          ),
        ),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.fundo,
        extendBody: true,
        appBar: const AppBarPadrao(titulo: 'Perfil'),
        bottomNavigationBar: const BottomNavBar(selectedIndex: 3),
        body: Stack(
          children: [
            const _AtmosphericBackground(),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.destaque,
                ),
              )
            else
              SafeArea(
                bottom: false,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _Header(),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            _ProfileCard(
                              nome: _nome,
                              email: _email.isEmpty
                                  ? 'E-mail não informado'
                                  : _email,
                              telefone: _mascararTelefone(_telefone),
                              cpf: _mascararCpf(_cpf),
                              onEditTap: _showEditProfileModal,
                            ),
                            const SizedBox(height: 18),
                            _AppearanceSection(
                              selectedMode: _appearanceMode,
                              onChanged: _alterarAparencia,
                            ),
                            const SizedBox(height: 18),
                            _SecuritySection(
                              onChangePassword: _showChangePasswordModal,
                              onResetPassword: _sendPasswordReset,
                            ),

                            const SizedBox(height: 22),
                            _AccountActions(
                              onLogout: _logout,
                              onDeleteAccount: _showDeleteAccountModal,
                            ),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileModal() {
    _showInfoModal(
      title: 'Editar perfil',
      icon: Icons.edit_rounded,
      message:
      'A edição direta do perfil ainda não está ativa nesta versão. Os dados exibidos vêm do usuário autenticado e do Firestore.',
    );
  }

  void _showChangePasswordModal() {
    _showInfoModal(
      title: 'Alterar senha',
      icon: Icons.lock_reset_rounded,
      message:
      'Para alterar a senha com segurança, use o fluxo de redefinição por e-mail.',
    );
  }

  Future<void> _sendPasswordReset() async {
    final email = FirebaseAuth.instance.currentUser?.email ?? _email;

    if (email.isEmpty) {
      _showSnackBar('Não encontramos um e-mail para redefinição de senha.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      _showSnackBar('E-mail de redefinição enviado para $email.');
    } catch (_) {
      if (!mounted) return;

      _showSnackBar('Não foi possível enviar o e-mail de redefinição.');
    }
  }

  void _showDeleteAccountModal() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Excluir conta',
            style: TextStyle(
              color: AppColors.destaque,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Essa ação exige uma confirmação segura antes de remover a conta. Para a entrega atual, o fluxo está sinalizado, mas não executa exclusão automática.',
            style: TextStyle(
              color: AppColors.textoFraco,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Entendi',
                style: TextStyle(
                  color: AppColors.destaque,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showInfoModal({
    required String title,
    required IconData icon,
    required String message,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _PremiumBottomSheet(
          title: title,
          icon: icon,
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.textoFraco,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Sair da conta',
            style: TextStyle(
              color: AppColors.destaque,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Tem certeza que deseja sair da sua conta?',
            style: TextStyle(
              color: AppColors.textoFraco,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: AppColors.textoFraco,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.destaque,
                foregroundColor: AppColors.fundo,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Sair',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }
}

// ─── Background ─────────────────────────────────────────────────────────────

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
                    AppColors.azul.withOpacity(0.22),
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
                    AppColors.destaque.withOpacity(0.07),
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
                    AppColors.roxo.withOpacity(0.18),
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

// ─── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 14),
          PremiumHeaderEyebrow(text: 'CONFIGURAÇÕES DA CONTA'),
          SizedBox(height: 14),
          Text(
            'Gerencie sua conta, aparência, privacidade e segurança.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textoFraco,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Card ───────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String nome;
  final String email;
  final String telefone;
  final String cpf;
  final VoidCallback onEditTap;

  const _ProfileCard({
    required this.nome,
    required this.email,
    required this.telefone,
    required this.cpf,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.destaque,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.destaque.withOpacity(0.16),
                      blurRadius: 26,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.card,
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.textoSecundario,
                    size: 48,
                  ),
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: GestureDetector(
                  onTap: onEditTap,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.destaque,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: AppColors.fundo,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            nome,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textoPrincipal,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _ProfileInfoRow(
            icon: Icons.email_outlined,
            label: 'E-mail',
            value: email,
          ),
          const SizedBox(height: 10),
          _ProfileInfoRow(
            icon: Icons.phone_outlined,
            label: 'Telefone',
            value: telefone,
          ),
          const SizedBox(height: 10),
          _ProfileInfoRow(
            icon: Icons.badge_outlined,
            label: 'CPF',
            value: cpf,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onEditTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.destaque,
                foregroundColor: AppColors.fundo,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Editar perfil',
                style: TextStyle(
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

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: premiumFieldDecoration(
        radius: 16,
      ),
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.destaque,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textoPrincipal,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sections ───────────────────────────────────────────────────────────────

class _AppearanceSection extends StatelessWidget {
  final AppAppearanceMode selectedMode;
  final ValueChanged<AppAppearanceMode> onChanged;

  const _AppearanceSection({
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Aparência',
      icon: Icons.palette_outlined,
      child: Column(
        children: [
          Row(
            children: [
              _ThemePill(
                label: 'Light',
                active: selectedMode == AppAppearanceMode.light,
                onTap: () => onChanged(AppAppearanceMode.light),
              ),
              const SizedBox(width: 8),
              _ThemePill(
                label: 'Dark',
                active: selectedMode == AppAppearanceMode.dark,
                onTap: () => onChanged(AppAppearanceMode.dark),
              ),
              const SizedBox(width: 8),
              _ThemePill(
                label: 'Auto',
                active: selectedMode == AppAppearanceMode.auto,
                onTap: () => onChanged(AppAppearanceMode.auto),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _AppearancePreview(
                  icon: Icons.light_mode_outlined,
                  active: selectedMode == AppAppearanceMode.light,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AppearancePreview(
                  icon: Icons.dark_mode_outlined,
                  active: selectedMode == AppAppearanceMode.dark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AppearancePreview(
                  icon: Icons.brightness_auto_outlined,
                  active: selectedMode == AppAppearanceMode.auto,
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
  final VoidCallback onChangePassword;
  final VoidCallback onResetPassword;

  const _SecuritySection({
    required this.onChangePassword,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Segurança',
      icon: Icons.shield_outlined,
      child: Column(
        children: [
          const _StatusRow(
            title: 'Conta autenticada',
            subtitle: 'Usuário conectado pelo Firebase Authentication',
            active: true,
          ),
          const SizedBox(height: 10),
          _ActionRow(
            title: 'Alterar senha',
            onTap: onChangePassword,
          ),
          _ActionRow(
            title: 'Redefinir senha por e-mail',
            onTap: onResetPassword,
          ),
        ],
      ),
    );
  }
}

class _AccountActions extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  const _AccountActions({
    required this.onLogout,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: AppColors.bordaClara,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.textoSecundario,
                size: 18,
              ),
              label: const Text(
                'Sair da conta',
                style: TextStyle(
                  color: AppColors.textoPrincipal,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onDeleteAccount,
            child: const Text(
              'Excluir conta',
              style: TextStyle(
                color: AppColors.textoFraco,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'MesclaInvest • v1.0.0',
            style: TextStyle(
              color: AppColors.destaque,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small Components ───────────────────────────────────────────────────────

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
      decoration: premiumCardDecoration(
        radius: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.destaque,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  title!,
                  style: const TextStyle(
                    color: AppColors.destaque,
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
  final VoidCallback onTap;

  const _ThemePill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 36,
            decoration: BoxDecoration(
              color: active ? AppColors.destaque : AppColors.campo,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active ? AppColors.destaque : AppColors.bordaClara,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.fundo : AppColors.textoFraco,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppearancePreview extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _AppearancePreview({
    required this.icon,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: premiumFieldDecoration(
        radius: 16,
      ).copyWith(
        color: active ? AppColors.cardElevado : AppColors.campo,
        border: Border.all(
          color: active
              ? AppColors.destaque.withOpacity(0.35)
              : AppColors.bordaClara,
        ),
      ),
      child: Icon(
        active ? Icons.check_circle_rounded : icon,
        color: active ? AppColors.destaque : AppColors.textoMuitoFraco,
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String title;
  final bool danger;
  final VoidCallback onTap;

  const _ActionRow({
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.campo,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.bordaClara,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: danger
                          ? AppColors.destaque
                          : AppColors.textoSecundario,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textoMuitoFraco,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: premiumFieldDecoration(
        radius: 16,
      ),
      padding: const EdgeInsets.all(14),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textoPrincipal,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textoMuitoFraco,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 42,
              height: 24,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: active ? AppColors.destaque : AppColors.bordaMedia,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Align(
                alignment: active ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: active ? AppColors.fundo : AppColors.textoFraco,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool active;

  const _StatusRow({
    required this.title,
    required this.subtitle,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: premiumFieldDecoration(
        radius: 16,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            active ? Icons.verified_rounded : Icons.info_outline_rounded,
            color: active ? AppColors.destaque : AppColors.textoMuitoFraco,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatusText(
              title: title,
              subtitle: subtitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  final String title;
  final String subtitle;

  const _StatusText({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textoPrincipal,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textoMuitoFraco,
            fontSize: 10,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _PremiumBottomSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _PremiumBottomSheet({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.bordaMedia,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.destaque.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.destaque.withOpacity(0.28),
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppColors.destaque,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textoPrincipal,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}