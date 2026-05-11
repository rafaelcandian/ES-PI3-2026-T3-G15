import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mescla_invest/widgets/premium_ui.dart';

import '../../models/balcao_model.dart';
import '../../themes/app_theme.dart';
import 'ordem_confirm_screen.dart';

class OrdemExeScreen extends StatefulWidget {
  final Oferta oferta;
  final ModoNegociacao modo;
  final List<Oferta> ofertasDisponiveis;

  const OrdemExeScreen({
    super.key,
    required this.oferta,
    required this.modo,
    required this.ofertasDisponiveis,
  });

  @override
  State<OrdemExeScreen> createState() => _OrdemExeScreenState();
}

class _OrdemExeScreenState extends State<OrdemExeScreen> {
  late int _quantidade;
  late double _preco;
  late final TextEditingController _quantidadeController;

  bool get _isCompra => widget.modo == ModoNegociacao.compra;

  double get _subtotal => _quantidade * _preco;

  double get _taxa => _subtotal * 0.004;

  double get _totalFinal => _isCompra ? _subtotal + _taxa : _subtotal - _taxa;

  double get _precoMedio {
    final ofertas = widget.ofertasDisponiveis
        .where((item) => item.simbolo == widget.oferta.simbolo)
        .toList();

    if (ofertas.isEmpty) return widget.oferta.preco;

    final soma = ofertas.fold<double>(
      0,
          (total, item) => total + item.preco,
    );

    return soma / ofertas.length;
  }

  double get _diferenca {
    if (_precoMedio == 0) return 0;
    return ((_preco - _precoMedio) / _precoMedio) * 100;
  }

  @override
  void initState() {
    super.initState();

    final quantidadeDisponivel = widget.oferta.quantidade;

    _quantidade = quantidadeDisponivel <= 0 ? 0 : quantidadeDisponivel;
    _preco = widget.oferta.preco;

    _quantidadeController = TextEditingController(
      text: _quantidade.toString(),
    );
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    super.dispose();
  }

  void _atualizarQuantidade(String value) {
    final maximo = widget.oferta.quantidade;

    if (value.isEmpty) {
      setState(() {
        _quantidade = 0;
      });
      return;
    }

    final quantidadeDigitada = int.tryParse(value) ?? 0;

    final quantidadeAjustada = quantidadeDigitada.clamp(1, maximo).toInt();

    if (quantidadeDigitada != quantidadeAjustada) {
      _quantidadeController.text = quantidadeAjustada.toString();
      _quantidadeController.selection = TextSelection.fromPosition(
        TextPosition(offset: _quantidadeController.text.length),
      );
    }

    setState(() {
      _quantidade = quantidadeAjustada;
    });
  }

  void _alterarQuantidadePeloBotao(int novaQuantidade) {
    final maximo = widget.oferta.quantidade;
    final quantidadeAjustada = novaQuantidade.clamp(1, maximo).toInt();

    setState(() {
      _quantidade = quantidadeAjustada;
      _quantidadeController.text = quantidadeAjustada.toString();
      _quantidadeController.selection = TextSelection.fromPosition(
        TextPosition(offset: _quantidadeController.text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isCompra ? AppColors.destaque : AppColors.azul;

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
                        _buildResumoStartup(accent),
                        const SizedBox(height: 18),
                        _buildComparacaoMercado(),
                        const SizedBox(height: 18),
                        _buildConfigOrdem(),
                        const SizedBox(height: 18),
                        _buildResumoFinanceiro(),
                        const SizedBox(height: 28),
                        _buildConfirmButton(accent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.destaque,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _isCompra ? 'Executar compra' : 'Executar venda',
            style: const TextStyle(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumHeaderEyebrow(
          text: _isCompra ? 'ORDEM DE COMPRA' : 'ORDEM DE VENDA',
        ),
        const SizedBox(height: 14),
        Text(
          _isCompra ? 'Comprar tokens' : 'Vender tokens',
          style: const TextStyle(
            color: AppColors.textoPrincipal,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isCompra
              ? 'Revise os dados antes de confirmar sua compra simulada.'
              : 'Revise os dados antes de confirmar sua venda simulada.',
          style: const TextStyle(
            color: AppColors.textoFraco,
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildResumoStartup(Color accent) {
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
              color: accent.withOpacity(0.13),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withOpacity(0.35),
              ),
            ),
            child: Center(
              child: Text(
                widget.oferta.simbolo,
                style: TextStyle(
                  color: accent,
                  fontSize: widget.oferta.simbolo.length > 3 ? 10 : 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.oferta.empresa,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textoPrincipal,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${widget.oferta.quantidade} tokens disponíveis • Spread ${widget.oferta.spread.toStringAsFixed(1)}%',
                  style: const TextStyle(
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

  Widget _buildComparacaoMercado() {
    return _InfoCard(
      title: 'Comparação de mercado',
      children: [
        _InfoRow(
          label: 'Preço da ordem',
          value: 'R\$ ${_preco.toStringAsFixed(2)}',
          destaque: true,
        ),
        const SizedBox(height: 10),
        _InfoRow(
          label: 'Preço médio',
          value: 'R\$ ${_precoMedio.toStringAsFixed(2)}',
        ),
        const SizedBox(height: 10),
        _InfoRow(
          label: 'Diferença',
          value: '${_diferenca >= 0 ? '+' : ''}${_diferenca.toStringAsFixed(1)}%',
        ),
      ],
    );
  }

  Widget _buildConfigOrdem() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: premiumCardDecoration(
        radius: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumHeaderEyebrow(text: 'CONFIGURAÇÃO DA ORDEM'),
          const SizedBox(height: 18),
          _QuantityControlBox(
            label: 'Quantidade de tokens',
            controller: _quantidadeController,
            quantidade: _quantidade,
            maximo: widget.oferta.quantidade,
            onChanged: _atualizarQuantidade,
            onMinus: () {
              if (_quantidade <= 1) return;

              HapticFeedback.selectionClick();
              _alterarQuantidadePeloBotao(_quantidade - 1);
            },
            onPlus: () {
              if (_quantidade >= widget.oferta.quantidade) return;

              HapticFeedback.selectionClick();
              _alterarQuantidadePeloBotao(_quantidade + 1);
            },
          ),
          const SizedBox(height: 14),
          _ControlBox(
            label: 'Preço por token',
            value: 'R\$ ${_preco.toStringAsFixed(2)}',
            onMinus: () {
              if (_preco <= 0.10) return;

              HapticFeedback.selectionClick();

              setState(() {
                _preco = (_preco - 0.10).clamp(0.10, 999999);
              });
            },
            onPlus: () {
              HapticFeedback.selectionClick();

              setState(() {
                _preco += 0.10;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResumoFinanceiro() {
    return _InfoCard(
      title: 'Resumo financeiro',
      children: [
        _InfoRow(
          label: 'Subtotal',
          value: 'R\$ ${_subtotal.toStringAsFixed(2)}',
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
          label: _isCompra ? 'Total estimado' : 'Valor líquido',
          value: 'R\$ ${_totalFinal.toStringAsFixed(2)}',
          destaque: true,
        ),
      ],
    );
  }

  Widget _buildConfirmButton(Color accent) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: _isCompra
              ? const LinearGradient(
            colors: [
              AppColors.destaqueClaro,
              AppColors.destaqueEscuro,
            ],
          )
              : const LinearGradient(
            colors: [
              AppColors.azul,
              AppColors.roxo,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.24),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _confirmarOrdem,
            child: Center(
              child: Text(
                _isCompra ? 'CONFIRMAR COMPRA' : 'CONFIRMAR VENDA',
                style: TextStyle(
                  color: _isCompra ? AppColors.fundo : AppColors.textoPrincipal,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmarOrdem() {
    if (_quantidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe uma quantidade válida de tokens.'),
        ),
      );
      return;
    }

    if (_quantidade > widget.oferta.quantidade) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A quantidade máxima disponível é ${widget.oferta.quantidade} tokens.',
          ),
        ),
      );
      return;
    }

    final ofertaFinal = Oferta(
      tipo: widget.oferta.tipo,
      quantidade: _quantidade,
      preco: _preco,
      empresa: widget.oferta.empresa,
      simbolo: widget.oferta.simbolo,
      variacao: widget.oferta.variacao,
      volume: widget.oferta.volume,
      spread: widget.oferta.spread,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrdemConfirmScreen(
          oferta: ofertaFinal,
          modo: widget.modo,
          totalFinal: _totalFinal,
          taxa: _taxa,
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
                color: destaque ? AppColors.textoPrincipal : AppColors.textoFraco,
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
                color: destaque ? AppColors.destaque : AppColors.textoPrincipal,
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

// ===================== CONTROLES =====================

class _QuantityControlBox extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int quantidade;
  final int maximo;
  final ValueChanged<String> onChanged;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _QuantityControlBox({
    required this.label,
    required this.controller,
    required this.quantidade,
    required this.maximo,
    required this.onChanged,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final limiteAtingido = maximo > 0 && quantidade >= maximo;
    final semTokens = maximo <= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: premiumFieldDecoration(
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Máximo disponível: $maximo tokens',
            style: const TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _RoundButton(
                icon: Icons.remove_rounded,
                onTap: semTokens ? null : onMinus,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: controller,
                    enabled: !semTokens,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: onChanged,
                    cursorColor: AppColors.destaque,
                    style: const TextStyle(
                      color: AppColors.textoPrincipal,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.card.withOpacity(0.7),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      hintText: '0',
                      hintStyle: const TextStyle(
                        color: AppColors.textoMuitoFraco,
                        fontWeight: FontWeight.w800,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.bordaClara,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.bordaClara,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.destaque,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _RoundButton(
                icon: Icons.add_rounded,
                onTap: semTokens ? null : onPlus,
              ),
            ],
          ),
          if (semTokens) ...[
            const SizedBox(height: 10),
            const Text(
              'Esta startup não possui tokens disponíveis para esta ordem.',
              style: TextStyle(
                color: AppColors.destaque,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else if (limiteAtingido) ...[
            const SizedBox(height: 10),
            const Text(
              'Você selecionou todos os tokens disponíveis desta oferta.',
              style: TextStyle(
                color: AppColors.destaque,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ControlBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _ControlBox({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: premiumFieldDecoration(
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _RoundButton(
                icon: Icons.remove_rounded,
                onTap: onMinus,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textoPrincipal,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              _RoundButton(
                icon: Icons.add_rounded,
                onTap: onPlus,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: enabled ? AppColors.card : AppColors.card.withOpacity(0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            color: enabled
                ? AppColors.destaque
                : AppColors.textoMuitoFraco.withOpacity(0.55),
            size: 20,
          ),
        ),
      ),
    );
  }
}