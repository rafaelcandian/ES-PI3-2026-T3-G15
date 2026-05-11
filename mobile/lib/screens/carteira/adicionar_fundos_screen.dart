import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mescla_invest/widgets/premium_ui.dart';
import 'package:mescla_invest/services/carteira_service.dart';

import '../../themes/app_theme.dart';

class AdicionarFundosScreen extends StatefulWidget {
  const AdicionarFundosScreen({super.key});

  @override
  State<AdicionarFundosScreen> createState() => _AdicionarFundosScreenState();
}

class _AdicionarFundosScreenState extends State<AdicionarFundosScreen> {
  final TextEditingController _valorController = TextEditingController();

  double _valor = 0.0;
  bool _loading = false;

  static const double _valorMinimo = 10.0;
  static const double _valorMaximo = 10000.0;

  final List<double> _valoresRapidos = [
    50,
    100,
    250,
    500,
  ];

  double get _taxa => 0.0;

  double get _totalCreditado => _valor - _taxa;

  bool get _valorValido => _valor >= _valorMinimo && _valor <= _valorMaximo;

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  void _atualizarValor(String value) {
    final valorNormalizado = value.replaceAll(',', '.');
    final valorDigitado = double.tryParse(valorNormalizado) ?? 0.0;

    setState(() {
      _valor = valorDigitado;
    });
  }

  void _selecionarValorRapido(double valor) {
    HapticFeedback.selectionClick();

    setState(() {
      _valor = valor;
      _valorController.text = valor.toStringAsFixed(2).replaceAll('.', ',');
      _valorController.selection = TextSelection.fromPosition(
        TextPosition(offset: _valorController.text.length),
      );
    });
  }

  Future<void> _confirmarAporte() async {
    FocusScope.of(context).unfocus();

    if (_valor <= 0) {
      _showSnackBar('Informe um valor para adicionar à carteira.');
      return;
    }

    if (_valor < _valorMinimo) {
      _showSnackBar(
        'O valor mínimo para aporte simulado é R\$ ${_valorMinimo.toStringAsFixed(2)}.',
      );
      return;
    }

    if (_valor > _valorMaximo) {
      _showSnackBar(
        'O valor máximo por aporte simulado é R\$ ${_valorMaximo.toStringAsFixed(2)}.',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await CarteiraService().addBalancePixSimulado(_totalCreditado);

      if (!mounted) return;

      _showSnackBar('Fundos adicionados com sucesso!');

      await Future.delayed(const Duration(milliseconds: 450));

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showSnackBar('Erro ao adicionar fundos: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: Stack(
        children: [
          const _AtmosphericBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 22),
                        _buildResumoCarteira(),
                        const SizedBox(height: 18),
                        _buildValorCard(),
                        const SizedBox(height: 18),
                        _buildMetodoCard(),
                        const SizedBox(height: 18),
                        _buildResumoFinanceiro(),
                        const SizedBox(height: 28),
                        _buildConfirmButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_loading) const _LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _loading
                  ? AppColors.textoMuitoFraco.withOpacity(0.45)
                  : AppColors.destaque,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Adicionar fundos',
            style: TextStyle(
              color: AppColors.destaque,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumHeaderEyebrow(
          text: 'PIX SIMULADO',
        ),
        SizedBox(height: 14),
        Text(
          'Adicionar saldo à carteira',
          style: TextStyle(
            color: AppColors.textoPrincipal,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Insira um valor fictício para simular um aporte na sua carteira de investimentos.',
          style: TextStyle(
            color: AppColors.textoFraco,
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildResumoCarteira() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: premiumCardDecoration(
        radius: 24,
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.destaque.withOpacity(0.13),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.destaque.withOpacity(0.35),
              ),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.destaque,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carteira Mescla Invest',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textoPrincipal,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Aporte fictício • Sem cobrança real',
                  style: TextStyle(
                    color: AppColors.textoMuitoFraco,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: premiumCardDecoration(
        radius: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumHeaderEyebrow(text: 'VALOR DO APORTE'),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: premiumFieldDecoration(
              radius: 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QUANTO DESEJA ADICIONAR?',
                  style: TextStyle(
                    color: AppColors.textoMuitoFraco,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _valorController,
                  enabled: !_loading,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9,.]'),
                    ),
                  ],
                  onChanged: _atualizarValor,
                  cursorColor: AppColors.destaque,
                  style: const TextStyle(
                    color: AppColors.textoPrincipal,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    prefixText: 'R\$ ',
                    prefixStyle: const TextStyle(
                      color: AppColors.destaque,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                    hintText: '0,00',
                    hintStyle: const TextStyle(
                      color: AppColors.textoMuitoFraco,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                    helperText:
                    'Mínimo R\$ ${_valorMinimo.toStringAsFixed(2)} • Máximo R\$ ${_valorMaximo.toStringAsFixed(2)}',
                    helperStyle: const TextStyle(
                      color: AppColors.textoMuitoFraco,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _valoresRapidos.map((valor) {
              final ativo = _valor == valor;

              return _QuickValueChip(
                label: 'R\$ ${valor.toStringAsFixed(0)}',
                ativo: ativo,
                onTap: _loading ? null : () => _selecionarValorRapido(valor),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodoCard() {
    return _InfoCard(
      title: 'Método de pagamento',
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.destaque.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.bordaDestaque,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.destaque.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pix_rounded,
                  color: AppColors.destaque,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pix simulado',
                      style: TextStyle(
                        color: AppColors.textoPrincipal,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Crédito fictício para uso no ambiente de testes.',
                      style: TextStyle(
                        color: AppColors.textoMuitoFraco,
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.destaque,
                size: 22,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumoFinanceiro() {
    return _InfoCard(
      title: 'Resumo do aporte',
      children: [
        _InfoRow(
          label: 'Valor solicitado',
          value: 'R\$ ${_valor.toStringAsFixed(2)}',
        ),
        const SizedBox(height: 10),
        _InfoRow(
          label: 'Taxa simulada',
          value: 'R\$ ${_taxa.toStringAsFixed(2)}',
        ),
        const SizedBox(height: 14),
        const Divider(
          color: AppColors.bordaClara,
          height: 1,
        ),
        const SizedBox(height: 14),
        _InfoRow(
          label: 'Total creditado',
          value: 'R\$ ${_totalCreditado.toStringAsFixed(2)}',
          destaque: true,
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    final disabled = _loading || !_valorValido;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Opacity(
        opacity: disabled ? 0.58 : 1,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.destaqueClaro,
                AppColors.destaqueEscuro,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.destaque.withOpacity(0.24),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: disabled ? null : _confirmarAporte,
              child: Center(
                child: Text(
                  _loading ? 'PROCESSANDO...' : 'CONFIRMAR APORTE',
                  style: const TextStyle(
                    color: AppColors.fundo,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
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
                    AppColors.azul.withOpacity(0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 240,
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
            bottom: 60,
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

// ===================== CARDS =====================

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: premiumCardDecoration(
        radius: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumHeaderEyebrow(text: title.toUpperCase()),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool destaque;

  const _InfoRow({
    required this.label,
    required this.value,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: destaque
          ? BoxDecoration(
        color: AppColors.destaque.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.bordaDestaque,
        ),
      )
          : premiumFieldDecoration(
        radius: 16,
      ),
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color:
                destaque ? AppColors.textoPrincipal : AppColors.textoFraco,
                fontSize: destaque ? 14 : 13,
                fontWeight: destaque ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                destaque ? AppColors.destaque : AppColors.textoPrincipal,
                fontSize: destaque ? 16 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== CHIPS =====================

class _QuickValueChip extends StatelessWidget {
  final String label;
  final bool ativo;
  final VoidCallback? onTap;

  const _QuickValueChip({
    required this.label,
    required this.ativo,
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: ativo ? AppColors.destaque : AppColors.campo,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: ativo ? AppColors.destaque : AppColors.bordaClara,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: ativo ? AppColors.fundo : AppColors.textoFraco,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== LOADING =====================

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fundo.withOpacity(0.72),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: premiumCardDecoration(
            radius: 24,
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(
                  color: AppColors.destaque,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Processando Pix simulado...',
                style: TextStyle(
                  color: AppColors.textoPrincipal,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}