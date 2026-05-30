import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mescla_invest/services/autenticacao.dart';
import 'package:mescla_invest/widgets/app_bar_padrao.dart';
import 'package:mescla_invest/widgets/bottom_nav_bar.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';
import 'package:mescla_invest/widgets/shared/app_button.dart';

import '../../themes/app_theme.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final AuthService _authService = AuthService();

  bool _loading = true;

  String _nome = 'Usuário';
  String _email = '';
  String _telefone = '';
  String _cpf = '';
  bool _twoFactorEnabled = false;

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
      bool twoFactorEnabled = false;

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      final data = doc.data();

      if (data != null) {
        nome = data['nome'] ?? data['name'] ?? data['displayName'] ?? nome;
        email = data['email'] ?? email;
        telefone =
            data['telefone'] ?? data['phone'] ?? data['celular'] ?? telefone;
        cpf = data['cpf'] ?? '';

        final twoFactorData = data['twoFactor'];

        if (twoFactorData is Map) {
          twoFactorEnabled = twoFactorData['enabled'] == true;
        }
      }

      if (!mounted) return;

      setState(() {
        _nome = nome.toString().trim().isEmpty ? 'Usuário' : nome.toString();
        _email = email.toString();
        _telefone = telefone.toString();
        _cpf = cpf.toString();
        _twoFactorEnabled = twoFactorEnabled;
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
        _twoFactorEnabled = false;
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
        extendBody: false,
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
                            _SecuritySection(
                              onResetPassword: _sendPasswordReset,
                              twoFactorEnabled: _twoFactorEnabled,
                              onToggleTwoFactor: _toggleTwoFactor,
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

  Future<void> _showEditProfileModal() async {
    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _EditProfileSheet(
          nomeInicial: _nome,
          telefoneInicial: _telefone,
          cpfInicial: _cpf,
          email: _email,
          onSave: _salvarPerfil,
        );
      },
    );

    if (resultado == true && mounted) {
      await _carregarDadosUsuario();
    }
  }

  Future<void> _salvarPerfil({
    required String nome,
    required String telefone,
    required String cpf,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    final telefoneLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final cpfLimpo = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    await user.updateDisplayName(nome);

    await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set(
      {
        'nome': nome,
        'displayName': nome,
        'email': user.email ?? _email,
        'telefone': telefoneLimpo,
        'cpf': cpfLimpo,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (!mounted) return;

    setState(() {
      _nome = nome;
      _telefone = telefoneLimpo;
      _cpf = cpfLimpo;
    });
  }

  Future<void> _sendPasswordReset() async {
    final email = FirebaseAuth.instance.currentUser?.email ?? _email;

    if (email.isEmpty) {
      _showPasswordResetDialog(
        title: 'E-mail não encontrado',
        message:
        'Não encontramos um e-mail vinculado à sua conta para enviar a redefinição de senha.',
        success: false,
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      _showPasswordResetDialog(
        title: 'E-mail enviado',
        message:
        'Enviamos um link de redefinição de senha para $email. Verifique sua caixa de entrada e o spam.',
        success: true,
      );
    } catch (_) {
      if (!mounted) return;

      _showPasswordResetDialog(
        title: 'Não foi possível enviar',
        message:
        'Tente novamente em alguns instantes. Se o problema continuar, confirme se seu e-mail está correto.',
        success: false,
      );
    }
  }

  void _showPasswordResetDialog({
    required String title,
    required String message,
    required bool success,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Icon(
                success
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: success ? AppColors.destaque : Colors.redAccent,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.destaque,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.textoFraco,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'OK',
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

  Future<void> _toggleTwoFactor() async {
    if (_twoFactorEnabled) {
      await _desativarTwoFactor();
    } else {
      await _ativarTwoFactor();
    }
  }

  Future<void> _desativarTwoFactor() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnackBar('Usuário não autenticado.');
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Desativar 2FA',
            style: TextStyle(
              color: AppColors.destaque,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Tem certeza que deseja desativar a autenticação de dois fatores?',
            style: TextStyle(
              color: AppColors.textoFraco,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: AppColors.textoFraco,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Desativar',
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

    if (confirmar != true) return;

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set(
        {
          'twoFactor': {
            'enabled': false,
            'secret': FieldValue.delete(),
            'otpAuthUri': FieldValue.delete(),
            'pendingSecret': FieldValue.delete(),
            'pendingCreatedAt': FieldValue.delete(),
            'disabledAt': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _twoFactorEnabled = false;
      });

      _showSnackBar('Autenticação de dois fatores desativada.');
    } catch (_) {
      if (!mounted) return;

      _showSnackBar(
        'Não foi possível desativar o 2FA. Verifique as regras do Firestore.',
      );
    }
  }

  Future<void> _ativarTwoFactor() async {
    try {
      final setup = await _authService.createTwoFactorSetup();

      if (!mounted) return;

      final ativou = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) {
          return _TwoFactorSetupSheet(
            secret: setup.secret ?? '',
            email: setup.email,
            onConfirm: _authService.confirmTwoFactorSetup,
          );
        },
      );

      if (ativou == true && mounted) {
        setState(() {
          _twoFactorEnabled = true;
        });

        _showSnackBar('Autenticação de dois fatores ativada.');
        await _carregarDadosUsuario();
      }
    } catch (_) {
      if (!mounted) return;

      _showSnackBar('Não foi possível iniciar a ativação do 2FA.');
    }
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
              fontWeight: FontWeight.w800,
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
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Sair',
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
      padding: EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          'Gerencie sua conta, privacidade e segurança.',
          textAlign: TextAlign.left,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
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
                      color: AppColors.destaque.withOpacity(0.12),
                      blurRadius: 22,
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
              fontWeight: FontWeight.w800,
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
          AppButton.primary(
            label: 'Editar perfil',
            icon: Icons.edit_rounded,
            onTap: onEditTap,
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
      decoration: premiumFieldDecoration(radius: 16),
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sections ───────────────────────────────────────────────────────────────

class _SecuritySection extends StatelessWidget {
  final VoidCallback onResetPassword;
  final bool twoFactorEnabled;
  final VoidCallback onToggleTwoFactor;

  const _SecuritySection({
    required this.onResetPassword,
    required this.twoFactorEnabled,
    required this.onToggleTwoFactor,
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
            title: 'Alterar/redefinir senha por e-mail',
            subtitle: 'Envia um link seguro pelo Firebase',
            icon: Icons.lock_reset_rounded,
            onTap: onResetPassword,
          ),
          const SizedBox(height: 2),
          _ToggleRow(
            title: 'Autenticação de dois fatores',
            subtitle: twoFactorEnabled
                ? 'Autenticação de dois fatores ativa'
                : 'Autenticação de dois fatores inativa',
            active: twoFactorEnabled,
            onTap: onToggleTwoFactor,
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
          AppButton.outline(
            label: 'Sair da conta',
            icon: Icons.logout_rounded,
            onTap: onLogout,
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
              fontWeight: FontWeight.w700,
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
      decoration: premiumCardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: AppColors.destaque,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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

class _ActionRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool danger;
  final VoidCallback onTap;

  const _ActionRow({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.campo,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.bordaClara,
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: AppColors.destaque,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: danger
                              ? AppColors.destaque
                              : AppColors.textoSecundario,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppColors.textoMuitoFraco,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
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
      decoration: premiumFieldDecoration(radius: 16),
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
                      fontWeight: FontWeight.w800,
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
      decoration: premiumFieldDecoration(radius: 16),
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
            fontWeight: FontWeight.w800,
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

class _ProfileEditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _ProfileEditField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: premiumFieldDecoration(radius: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        validator: validator,
        cursorColor: AppColors.destaque,
        style: const TextStyle(
          color: AppColors.textoPrincipal,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          icon: Icon(
            icon,
            color: AppColors.destaque,
            size: 19,
          ),
          labelText: label,
          labelStyle: const TextStyle(
            color: AppColors.textoMuitoFraco,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          errorStyle: const TextStyle(
            color: Colors.redAccent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.length > 11) {
      text = text.substring(0, 11);
    }

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');

      buffer.write(text[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}

class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.length > 11) {
      text = text.substring(0, 11);
    }

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == 7) buffer.write('-');

      buffer.write(text[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final String nomeInicial;
  final String telefoneInicial;
  final String cpfInicial;
  final String email;
  final Future<void> Function({
  required String nome,
  required String telefone,
  required String cpf,
  }) onSave;

  const _EditProfileSheet({
    required this.nomeInicial,
    required this.telefoneInicial,
    required this.cpfInicial,
    required this.email,
    required this.onSave,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _cpfController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _nomeController = TextEditingController(text: widget.nomeInicial);
    _telefoneController = TextEditingController(
      text: _formatarTelefoneInicial(widget.telefoneInicial),
    );
    _cpfController = TextEditingController(
      text: _formatarCpfInicial(widget.cpfInicial),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  static String _formatarCpfInicial(String cpf) {
    final numeros = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    if (numeros.length != 11) {
      return cpf;
    }

    return '${numeros.substring(0, 3)}.${numeros.substring(3, 6)}.${numeros.substring(6, 9)}-${numeros.substring(9, 11)}';
  }

  static String _formatarTelefoneInicial(String telefone) {
    final numeros = telefone.replaceAll(RegExp(r'[^0-9]'), '');

    if (numeros.length != 11) {
      return telefone;
    }

    return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 7)}-${numeros.substring(7, 11)}';
  }

  bool _validarCPF(String cpf) {
    final numeros = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    if (numeros.length != 11) return false;
    if (RegExp(r'^(\d)\1*$').hasMatch(numeros)) return false;

    int calcularDigito(String base) {
      int soma = 0;

      for (int i = 0; i < base.length; i++) {
        soma += int.parse(base[i]) * (base.length + 1 - i);
      }

      final resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    }

    final primeiroDigito = calcularDigito(numeros.substring(0, 9));
    final segundoDigito = calcularDigito(numeros.substring(0, 10));

    return primeiroDigito == int.parse(numeros[9]) &&
        segundoDigito == int.parse(numeros[10]);
  }

  bool _validarTelefone(String telefone) {
    final numeros = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    return numeros.length == 11;
  }

  String? _validarNome(String? value) {
    final nome = value?.trim() ?? '';

    if (nome.isEmpty) return 'Campo obrigatório';

    if (nome.split(RegExp(r'\s+')).length < 2) {
      return 'Informe nome e sobrenome';
    }

    return null;
  }

  String? _validarCampoCpf(String? value) {
    final cpf = value?.trim() ?? '';

    if (cpf.isEmpty) return 'Campo obrigatório';
    if (!_validarCPF(cpf)) return 'CPF inválido';

    return null;
  }

  String? _validarCampoTelefone(String? value) {
    final telefone = value?.trim() ?? '';

    if (telefone.isEmpty) return 'Campo obrigatório';
    if (!_validarTelefone(telefone)) return 'Telefone inválido';

    return null;
  }

  Future<void> _salvar() async {
    FocusScope.of(context).unfocus();

    final valido = _formKey.currentState?.validate() ?? false;

    if (!valido) return;

    setState(() => _saving = true);

    try {
      await widget.onSave(
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text.trim(),
        cpf: _cpfController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Não foi possível atualizar o perfil.',
            style: TextStyle(color: AppColors.textoPrincipal),
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

  @override
  Widget build(BuildContext context) {
    return _PremiumBottomSheet(
      title: 'Editar perfil',
      icon: Icons.edit_rounded,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProfileEditField(
                controller: _nomeController,
                label: 'Nome completo',
                icon: Icons.person_outline_rounded,
                enabled: !_saving,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                validator: _validarNome,
              ),
              const SizedBox(height: 12),
              _ProfileEditField(
                controller: _telefoneController,
                label: 'Telefone celular',
                icon: Icons.phone_outlined,
                enabled: !_saving,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TelefoneInputFormatter(),
                ],
                validator: _validarCampoTelefone,
              ),
              const SizedBox(height: 12),
              _ProfileEditField(
                controller: _cpfController,
                label: 'CPF',
                icon: Icons.badge_outlined,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CpfInputFormatter(),
                ],
                validator: _validarCampoCpf,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: premiumFieldDecoration(radius: 16),
                child: Text(
                  widget.email.isEmpty
                      ? 'E-mail não informado'
                      : 'E-mail: ${widget.email}',
                  style: const TextStyle(
                    color: AppColors.textoMuitoFraco,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              AppButton.primary(
                label: 'Salvar alterações',
                loading: _saving,
                onTap: _saving ? null : _salvar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TwoFactorSetupSheet extends StatefulWidget {
  final String secret;
  final String email;
  final Future<String?> Function(String code) onConfirm;

  const _TwoFactorSetupSheet({
    required this.secret,
    required this.email,
    required this.onConfirm,
  });

  @override
  State<_TwoFactorSetupSheet> createState() => _TwoFactorSetupSheetState();
}

class _TwoFactorSetupSheetState extends State<_TwoFactorSetupSheet> {
  final _codigoController = TextEditingController();

  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final codigo = _codigoController.text.trim();

    setState(() {
      _erro = null;
    });

    if (!RegExp(r'^\d{6}$').hasMatch(codigo)) {
      setState(() {
        _erro = 'Digite o código de 6 dígitos.';
      });
      return;
    }

    setState(() => _loading = true);

    final erro = await widget.onConfirm(codigo);

    if (!mounted) return;

    setState(() => _loading = false);

    if (erro == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _erro = erro.toLowerCase().contains('codigo') ||
                erro.toLowerCase().contains('código')
            ? 'Código inválido. Confira o Microsoft Authenticator e tente novamente.'
            : 'Não foi possível ativar o 2FA. Tente novamente.';
      });
    }
  }

  void _copiarChave() {
    Clipboard.setData(ClipboardData(text: widget.secret));
    _showLocalSnack('Chave copiada.');
  }

  void _showLocalSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textoPrincipal),
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
    return _PremiumBottomSheet(
      title: 'Ativar 2FA',
      icon: Icons.shield_outlined,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Adicione a chave abaixo no Microsoft Authenticator e depois digite o código de 6 dígitos gerado pelo app.',
              style: TextStyle(
                color: AppColors.textoFraco,
                height: 1.5,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: premiumFieldDecoration(radius: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chave manual',
                    style: TextStyle(
                      color: AppColors.textoMuitoFraco,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    widget.secret,
                    style: const TextStyle(
                      color: AppColors.textoPrincipal,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppButton.outline(
                    label: 'Copiar chave',
                    icon: Icons.copy_rounded,
                    onTap: _copiarChave,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ProfileEditField(
              controller: _codigoController,
              label: 'Código do autenticador',
              icon: Icons.pin_outlined,
              enabled: !_loading,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            if (_erro != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.redAccent.withOpacity(0.38),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _erro!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            AppButton.primary(
              label: 'Confirmar e ativar',
              loading: _loading,
              onTap: _loading ? null : _confirmar,
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
                    fontWeight: FontWeight.w800,
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