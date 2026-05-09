import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mescla_invest/widgets/bottom_nav_bar.dart';
import '../auth/app_theme.dart';

enum AppearanceMode {
  light,
  dark,
  auto,
}

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  AppearanceMode _appearanceMode = AppearanceMode.dark;

  bool _ocultarSaldo = true;
  bool _notificarValorizacao = true;
  bool _notificarCompraVenda = true;
  bool _notificarNoticias = false;
  bool _notificarPerguntas = true;

  final String _nome = 'Guilherme Moraes';
  final String _email = 'guilherme@example.com';
  final String _telefone = '+55 19 99999-9999';
  final String _cpf = '123.456.789-00';

  String get _appearanceLabel {
    switch (_appearanceMode) {
      case AppearanceMode.light:
        return 'Light';
      case AppearanceMode.dark:
        return 'Dark';
      case AppearanceMode.auto:
        return 'Auto';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.fundoEscuro,
        extendBody: true,
        bottomNavigationBar: const BottomNavBar(selectedIndex: 3),
        body: Stack(
          children: [
            const _AtmosphericBackground(),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _TopBar(
                          onSettingsTap: _showSettingsModal,
                        ),
                        const SizedBox(height: 24),
                        const _Header(),
                        const SizedBox(height: 20),
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
                            email: _email,
                            telefone: _telefone,
                            onEditTap: _showEditProfileModal,
                          ),

                          const SizedBox(height: 18),

                          _AppearanceSection(
                            selectedMode: _appearanceMode,
                            onChanged: (mode) {
                              setState(() {
                                _appearanceMode = mode;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Modo de aparência alterado para $_appearanceLabel.',
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
                            },
                          ),

                          const SizedBox(height: 18),

                          _SecuritySection(
                            onChangePassword: _showChangePasswordModal,
                            onResetPassword: _sendPasswordReset,
                            onLogoutAllDevices: _showLogoutAllDevicesModal,
                          ),

                          const SizedBox(height: 18),

                          _NotificationsSection(
                            valorizacao: _notificarValorizacao,
                            compraVenda: _notificarCompraVenda,
                            noticias: _notificarNoticias,
                            perguntas: _notificarPerguntas,
                            onValorizacaoChanged: (value) {
                              setState(() => _notificarValorizacao = value);
                            },
                            onCompraVendaChanged: (value) {
                              setState(() => _notificarCompraVenda = value);
                            },
                            onNoticiasChanged: (value) {
                              setState(() => _notificarNoticias = value);
                            },
                            onPerguntasChanged: (value) {
                              setState(() => _notificarPerguntas = value);
                            },
                          ),

                          const SizedBox(height: 18),

                          _PrivacySection(
                            ocultarSaldo: _ocultarSaldo,
                            onOcultarSaldoChanged: (value) {
                              setState(() => _ocultarSaldo = value);
                            },
                            onGerenciarDados: _showDataManagementModal,
                            onVisualizarDados: _showCpfTelefoneModal,
                            onDispositivos: _showConnectedDevicesModal,
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

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _PremiumBottomSheet(
          title: 'Configurações',
          icon: Icons.settings_outlined,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ModalActionTile(
                icon: Icons.palette_outlined,
                title: 'Aparência atual',
                subtitle: _appearanceLabel,
              ),
              _ModalActionTile(
                icon: Icons.visibility_off_outlined,
                title: 'Ocultar saldo',
                subtitle: _ocultarSaldo ? 'Ativado' : 'Desativado',
              ),
              _ModalActionTile(
                icon: Icons.lock_outline_rounded,
                title: 'Privacidade',
                subtitle: 'Gerencie dados pessoais e segurança',
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileModal() {
    _showInfoModal(
      title: 'Editar perfil',
      icon: Icons.edit_rounded,
      message:
      'Nesta versão simulada, os dados do perfil são exibidos localmente. Depois podemos conectar essa edição ao Firebase.',
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

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'E-mail de redefinição enviado para $email.',
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
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Não foi possível enviar o e-mail de redefinição.',
            style: TextStyle(
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
  }

  void _showLogoutAllDevicesModal() {
    _showInfoModal(
      title: 'Logout de dispositivos',
      icon: Icons.devices_other_rounded,
      message:
      'Essa ação exige integração específica com sessões/dispositivos no backend. Por enquanto, o app permite sair da sessão atual.',
    );
  }

  void _showDataManagementModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _PremiumBottomSheet(
          title: 'Gerenciamento de dados',
          icon: Icons.storage_outlined,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ModalActionTile(
                icon: Icons.person_outline_rounded,
                title: 'Dados pessoais',
                subtitle: 'Nome, e-mail, CPF e telefone cadastrados',
              ),
              _ModalActionTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Dados financeiros simulados',
                subtitle: 'Carteira, ativos e ordens de negociação',
              ),
              _ModalActionTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Interações',
                subtitle: 'Perguntas públicas e conversas privadas',
              ),
              _ModalActionTile(
                icon: Icons.download_rounded,
                title: 'Exportar dados',
                subtitle: 'Recurso previsto para integração futura',
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCpfTelefoneModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _PremiumBottomSheet(
          title: 'CPF e telefone',
          icon: Icons.badge_outlined,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DataRow(
                label: 'CPF',
                value: _cpf,
              ),
              const SizedBox(height: 12),
              _DataRow(
                label: 'Telefone',
                value: _telefone,
              ),
              const SizedBox(height: 16),
              const Text(
                'Esses dados são sensíveis e devem ser exibidos apenas para o próprio usuário autenticado.',
                style: TextStyle(
                  color: AppColors.textoMuitoFraco,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConnectedDevicesModal() {
    _showInfoModal(
      title: 'Dispositivos conectados',
      icon: Icons.devices_rounded,
      message:
      'Aqui futuramente será exibida a lista de dispositivos com sessões ativas.',
    );
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
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Essa ação é sensível. Para excluir a conta de verdade, o ideal é criar um fluxo com confirmação de senha e remoção segura no Firebase.',
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
            right: -110,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.azul.withOpacity(0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 170,
            left: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.destaque.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -100,
            child: Container(
              width: 290,
              height: 290,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.roxo.withOpacity(0.15),
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

class _TopBar extends StatelessWidget {
  final VoidCallback onSettingsTap;

  const _TopBar({
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MESCLAINVEST',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.destaque,
                  letterSpacing: 2.4,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Área do usuário',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textoMuitoFraco,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSettingsTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.destaque.withOpacity(0.35),
                  width: 1.4,
                ),
                gradient: const LinearGradient(
                  colors: [
                    AppColors.campo,
                    AppColors.card,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: AppColors.destaque,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderEyebrow(text: 'CONFIGURAÇÕES DA CONTA'),
          SizedBox(height: 14),
          Text(
            'Perfil',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textoPrincipal,
              height: 1.15,
              letterSpacing: -0.4,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Gerencie sua conta, preferências, privacidade e segurança.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textoFraco,
              height: 1.5,
            ),
          ),
        ],
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

// ─── Profile Card ───────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String nome;
  final String email;
  final String telefone;
  final VoidCallback onEditTap;

  const _ProfileCard({
    required this.nome,
    required this.email,
    required this.telefone,
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
                width: 94,
                height: 94,
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
                  radius: 45,
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
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.destaque,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: AppColors.card,
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
          const SizedBox(height: 5),
          Text(
            email,
            style: const TextStyle(
              color: AppColors.textoFraco,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            telefone,
            style: const TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: onEditTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.destaque,
                foregroundColor: AppColors.card,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28),
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

// ─── Sections ───────────────────────────────────────────────────────────────

class _AppearanceSection extends StatelessWidget {
  final AppearanceMode selectedMode;
  final ValueChanged<AppearanceMode> onChanged;

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
                active: selectedMode == AppearanceMode.light,
                onTap: () => onChanged(AppearanceMode.light),
              ),
              const SizedBox(width: 8),
              _ThemePill(
                label: 'Dark',
                active: selectedMode == AppearanceMode.dark,
                onTap: () => onChanged(AppearanceMode.dark),
              ),
              const SizedBox(width: 8),
              _ThemePill(
                label: 'Auto',
                active: selectedMode == AppearanceMode.auto,
                onTap: () => onChanged(AppearanceMode.auto),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _AppearancePreview(
                  icon: Icons.light_mode_outlined,
                  active: selectedMode == AppearanceMode.light,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AppearancePreview(
                  icon: Icons.dark_mode_outlined,
                  active: selectedMode == AppearanceMode.dark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AppearancePreview(
                  icon: Icons.brightness_auto_outlined,
                  active: selectedMode == AppearanceMode.auto,
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
  final VoidCallback onLogoutAllDevices;

  const _SecuritySection({
    required this.onChangePassword,
    required this.onResetPassword,
    required this.onLogoutAllDevices,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Segurança',
      icon: Icons.shield_outlined,
      child: Column(
        children: [
          const _StatusRow(
            title: '2FA ativo',
            subtitle: 'Autenticação em 2 fatores',
            active: true,
          ),
          const SizedBox(height: 10),
          _ActionRow(
            title: 'Alterar senha',
            onTap: onChangePassword,
          ),
          _ActionRow(
            title: 'Redefinir senha',
            onTap: onResetPassword,
          ),
          _ActionRow(
            title: 'Logout de todos os dispositivos',
            danger: true,
            onTap: onLogoutAllDevices,
          ),
        ],
      ),
    );
  }
}

class _NotificationsSection extends StatelessWidget {
  final bool valorizacao;
  final bool compraVenda;
  final bool noticias;
  final bool perguntas;

  final ValueChanged<bool> onValorizacaoChanged;
  final ValueChanged<bool> onCompraVendaChanged;
  final ValueChanged<bool> onNoticiasChanged;
  final ValueChanged<bool> onPerguntasChanged;

  const _NotificationsSection({
    required this.valorizacao,
    required this.compraVenda,
    required this.noticias,
    required this.perguntas,
    required this.onValorizacaoChanged,
    required this.onCompraVendaChanged,
    required this.onNoticiasChanged,
    required this.onPerguntasChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Notificações',
      icon: Icons.notifications_outlined,
      child: Column(
        children: [
          _CheckRow(
            title: 'Valorização de tokens',
            checked: valorizacao,
            onTap: () => onValorizacaoChanged(!valorizacao),
          ),
          _CheckRow(
            title: 'Alertas de compra e venda',
            checked: compraVenda,
            onTap: () => onCompraVendaChanged(!compraVenda),
          ),
          _CheckRow(
            title: 'Notícias das startups',
            checked: noticias,
            onTap: () => onNoticiasChanged(!noticias),
          ),
          _CheckRow(
            title: 'Avisos de perguntas respondidas',
            checked: perguntas,
            onTap: () => onPerguntasChanged(!perguntas),
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final bool ocultarSaldo;
  final ValueChanged<bool> onOcultarSaldoChanged;
  final VoidCallback onGerenciarDados;
  final VoidCallback onVisualizarDados;
  final VoidCallback onDispositivos;

  const _PrivacySection({
    required this.ocultarSaldo,
    required this.onOcultarSaldoChanged,
    required this.onGerenciarDados,
    required this.onVisualizarDados,
    required this.onDispositivos,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Privacidade',
      icon: Icons.lock_outline_rounded,
      child: Column(
        children: [
          _ActionRow(
            title: 'Gerenciamento de dados',
            onTap: onGerenciarDados,
          ),
          _ActionRow(
            title: 'Visualizar CPF e telefone',
            onTap: onVisualizarDados,
          ),
          _ToggleRow(
            title: 'Ocultar saldo',
            subtitle: 'Esconde valores sensíveis na tela',
            active: ocultarSaldo,
            onTap: () => onOcultarSaldoChanged(!ocultarSaldo),
          ),
          const SizedBox(height: 10),
          _ActionRow(
            title: 'Dispositivos conectados',
            onTap: onDispositivos,
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
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.bordaClara,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
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
                Icon(
                  icon,
                  color: AppColors.destaque,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Text(
                  title!,
                  style: const TextStyle(
                    color: AppColors.textoPrincipal,
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
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 34,
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
                color: active ? AppColors.card : AppColors.textoFraco,
                fontSize: 12,
                fontWeight: FontWeight.w900,
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
      decoration: BoxDecoration(
        color: active ? AppColors.campo : AppColors.fundoEscuro,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.destaque.withOpacity(0.35) : AppColors.bordaClara,
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
                      color: danger ? AppColors.destaque : AppColors.textoSecundario,
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
    return GestureDetector(
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
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
                  color: active ? AppColors.card : AppColors.textoFraco,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
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
    return Row(
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
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textoMuitoFraco,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String title;
  final bool checked;
  final VoidCallback onTap;

  const _CheckRow({
    required this.title,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 40,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              checked
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: checked ? AppColors.destaque : AppColors.textoMuitoFraco,
              size: 19,
            ),
          ],
        ),
      ),
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

class _ModalActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ModalActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.campo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.bordaClara,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.destaque,
            size: 20,
          ),
          const SizedBox(width: 12),
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

class _DataRow extends StatelessWidget {
  final String label;
  final String value;

  const _DataRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.campo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.bordaClara,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textoFraco,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.destaque,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}