import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mescla_invest/models/balcao_model.dart';
import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';
import 'package:mescla_invest/widgets/shared/app_snackbar.dart';
import 'package:mescla_invest/widgets/shared/atmospheric_background.dart';
import 'package:mescla_invest/widgets/shared/gradient_button.dart';
import 'package:mescla_invest/widgets/shared/icon_box.dart';
import 'package:mescla_invest/widgets/shared/info_row.dart';
import 'package:mescla_invest/widgets/shared/section_card.dart';
import 'package:mescla_invest/widgets/shared/ticker_box.dart';

import 'ordem_confirm_screen.dart';

/// Tela responsável por configurar uma ordem de compra ou venda.
///
/// Aqui o usuário ajusta quantidade, preço por token, vê comparação de mercado
/// e revisa o resumo financeiro antes de seguir para a confirmação.
class OrdemExeScreen extends StatefulWidget {
  final Oferta oferta;
  final ModoNegociacao modo;
  final List<Oferta> ofertasDisponiveis;
  final double investimentoMinimo;
  final bool compraDireto;

  const OrdemExeScreen({
    super.key,
    required this.oferta,
    required this.modo,
    required this.ofertasDisponiveis,
    this.investimentoMinimo = 0.0,
    this.compraDireto = false,
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
      setState(() => _quantidade = 0);
      return;
    }

    final quantidadeDigitada = int.tryParse(value) ?? 0;
    final quantidadeAjustada = quantidadeDigitada.clamp(1, maximo).toInt();

    if (quantidadeDigitada != quantidadeAjustada) {
      _atualizarControllerQuantidade(quantidadeAjustada);
    }

    setState(() => _quantidade = quantidadeAjustada);
  }

  void _alterarQuantidade(int novaQuantidade) {
    final maximo = widget.oferta.quantidade;
    final quantidadeAjustada = novaQuantidade.clamp(1, maximo).toInt();

    HapticFeedback.selectionClick();

    setState(() {
      _quantidade = quantidadeAjustada;
      _atualizarControllerQuantidade(quantidadeAjustada);
    });
  }

  void _selecionarPercentual(double percentual) {
    final maximo = widget.oferta.quantidade;
    final novaQuantidade = (maximo * percentual).round().clamp(1, maximo);

    _alterarQuantidade(novaQuantidade.toInt());
  }

  void _atualizarControllerQuantidade(int value) {
    _quantidadeController.text = value.toString();
    _quantidadeController.selection = TextSelection.fromPosition(
      TextPosition(offset: _quantidadeController.text.length),
    );
  }

  void _alterarPreco(double delta) {
    HapticFeedback.selectionClick();

    setState(() {
      _preco = (_preco + delta).clamp(0.10, 999999);
    });
  }

  void _confirmarOrdem() {
    if (_quantidade <= 0) {
      AppSnackBar.show(
        context,
        message: 'Informe uma quantidade válida de tokens.',
        error: true,
      );
      return;
    }

    if (_quantidade > widget.oferta.quantidade) {
      AppSnackBar.show(
        context,
        message:
        'A quantidade máxima disponível é ${widget.oferta.quantidade} tokens.',
        error: true,
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
      startupId: widget.oferta.startupId, // propaga o startupId para a tela de confirmação
    );

    final totalOrdem = _quantidade * _preco;
    final atingiuMinimo = !widget.compraDireto || totalOrdem >= widget.investimentoMinimo;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrdemConfirmScreen(
          oferta: ofertaFinal,
          modo: widget.modo,
          totalFinal: _totalFinal,
          taxa: _taxa,
          atingiuMinimo: atingiuMinimo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionLabel = _isCompra ? 'compra' : 'venda';

    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: Stack(
        children: [
          const AtmosphericBackground(),
          SafeArea(
            child: Column(
              children: [
                _OrderTopBar(
                  title: _isCompra ? 'Executar compra' : 'Executar venda',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _OrderHeader(isCompra: _isCompra),
                        const SizedBox(height: 22),
                        _StartupOrderHero(
                          oferta: widget.oferta,
                          isCompra: _isCompra,
                          preco: _preco,
                        ),
                        const SizedBox(height: 18),
                        _buildMarketComparison(),
                        const SizedBox(height: 18),
                        _buildOrderConfiguration(),
                        const SizedBox(height: 18),
                        _buildFinancialSummary(),
                        const SizedBox(height: 28),
                        GradientButton(
                          label: 'Confirmar $actionLabel',
                          icon: _isCompra
                              ? Icons.shopping_bag_rounded
                              : Icons.sell_rounded,
                          height: 56,
                          radius: 18,
                          onTap: _confirmarOrdem,
                        ),
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

  /// Cards de comparação de preço da ordem versus preço médio do mercado.
  Widget _buildMarketComparison() {
    return SectionCard(
      title: 'Comparação de mercado',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MarketMetricTile(
                  label: 'Preço da ordem',
                  value: 'R\$ ${_preco.toStringAsFixed(2)}',
                  destaque: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MarketMetricTile(
                  label: 'Preço médio',
                  value: 'R\$ ${_precoMedio.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MarketMetricTile(
            label: 'Diferença',
            value:
            '${_diferenca >= 0 ? '+' : ''}${_diferenca.toStringAsFixed(1)}%',
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  /// Área de ajuste de quantidade e preço por token.
  ///
  /// Inclui botões rápidos de percentual para dar cara de app financeiro.
  Widget _buildOrderConfiguration() {
    return SectionCard(
      title: 'Configuração da ordem',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuantityControlBox(
            controller: _quantidadeController,
            quantidade: _quantidade,
            maximo: widget.oferta.quantidade,
            onChanged: _atualizarQuantidade,
            onMinus: () {
              if (_quantidade > 1) _alterarQuantidade(_quantidade - 1);
            },
            onPlus: () {
              if (_quantidade < widget.oferta.quantidade) {
                _alterarQuantidade(_quantidade + 1);
              }
            },
          ),
          const SizedBox(height: 12),
          _QuickAmountButtons(
            onSelected: _selecionarPercentual,
          ),
          const SizedBox(height: 14),
          _PriceControlBox(
            value: 'R\$ ${_preco.toStringAsFixed(2)}',
            onMinus: () => _alterarPreco(-0.10),
            onPlus: () => _alterarPreco(0.10),
          ),
        ],
      ),
    );
  }

  /// Resumo final antes da confirmação.
  Widget _buildFinancialSummary() {
    return SectionCard(
      title: 'Resumo financeiro',
      child: Column(
        children: [
          InfoRow(
            label: 'Quantidade',
            value: '$_quantidade tokens',
            boxed: true,
          ),
          const SizedBox(height: 10),
          InfoRow(
            label: 'Subtotal',
            value: 'R\$ ${_subtotal.toStringAsFixed(2)}',
            boxed: true,
          ),
          const SizedBox(height: 10),
          InfoRow(
            label: 'Taxa simulada',
            value: 'R\$ ${_taxa.toStringAsFixed(2)}',
            boxed: true,
          ),
          const SizedBox(height: 14),
          const Divider(
            color: AppColors.bordaClara,
            height: 1,
          ),
          const SizedBox(height: 14),
          InfoRow(
            label: _isCompra ? 'Total estimado' : 'Valor líquido',
            value: 'R\$ ${_totalFinal.toStringAsFixed(2)}',
            destaque: true,
            boxed: true,
          ),
        ],
      ),
    );
  }
}

/// Barra superior comum da execução da ordem.
class _OrderTopBar extends StatelessWidget {
  final String title;

  const _OrderTopBar({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
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
            title,
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
}

/// Cabeçalho textual da ordem.
class _OrderHeader extends StatelessWidget {
  final bool isCompra;

  const _OrderHeader({
    required this.isCompra,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumHeaderEyebrow(
          text: isCompra ? 'ORDEM DE COMPRA' : 'ORDEM DE VENDA',
        ),
        const SizedBox(height: 14),
        Text(
          isCompra ? 'Comprar tokens' : 'Vender tokens',
          style: const TextStyle(
            color: AppColors.textoPrincipal,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Revise os detalhes da operação antes de confirmar.',
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
}

/// Hero da startup negociada.
class _StartupOrderHero extends StatelessWidget {
  final Oferta oferta;
  final bool isCompra;
  final double preco;

  const _StartupOrderHero({
    required this.oferta,
    required this.isCompra,
    required this.preco,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: premiumCardDecoration(radius: 26),
      child: Row(
        children: [
          TickerBox(
            simbolo: oferta.simbolo,
            size: 58,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  oferta.empresa,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textoPrincipal,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${oferta.quantidade} tokens disponíveis • Spread ${oferta.spread.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppColors.textoMuitoFraco,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Preço unitário: R\$ ${preco.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.destaque,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _OrderPill(
            label: isCompra ? 'Compra' : 'Venda',
            icon: isCompra ? Icons.shopping_bag_rounded : Icons.sell_rounded,
          ),
        ],
      ),
    );
  }
}

class _OrderPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _OrderPill({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.destaque.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.bordaDestaque,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.destaque,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.destaque,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final bool destaque;
  final bool fullWidth;

  const _MarketMetricTile({
    required this.label,
    required this.value,
    this.destaque = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: destaque
          ? BoxDecoration(
        color: AppColors.destaque.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.bordaDestaque,
        ),
      )
          : premiumFieldDecoration(radius: 18),
      child: Column(
        crossAxisAlignment:
        fullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textoFraco,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: destaque ? AppColors.destaque : AppColors.textoPrincipal,
              fontSize: destaque ? 18 : 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityControlBox extends StatelessWidget {
  final TextEditingController controller;
  final int quantidade;
  final int maximo;
  final ValueChanged<String> onChanged;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _QuantityControlBox({
    required this.controller,
    required this.quantidade,
    required this.maximo,
    required this.onChanged,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final semTokens = maximo <= 0;
    final limiteAtingido = maximo > 0 && quantidade >= maximo;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: premiumFieldDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUANTIDADE',
            style: TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Você possui até $maximo tokens disponíveis para esta ordem.',
            style: const TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _RoundActionButton(
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
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.card.withValues(alpha: 0.70),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
                      hintText: '0',
                      hintStyle: const TextStyle(
                        color: AppColors.textoMuitoFraco,
                        fontWeight: FontWeight.w800,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.bordaClara,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.bordaClara,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.destaque,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _RoundActionButton(
                icon: Icons.add_rounded,
                onTap: semTokens ? null : onPlus,
              ),
            ],
          ),
          if (semTokens || limiteAtingido) ...[
            const SizedBox(height: 10),
            Text(
              semTokens
                  ? 'Esta oferta não possui tokens disponíveis.'
                  : 'Você selecionou todos os tokens disponíveis.',
              style: const TextStyle(
                color: AppColors.destaque,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickAmountButtons extends StatelessWidget {
  final ValueChanged<double> onSelected;

  const _QuickAmountButtons({
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      ('25%', 0.25),
      ('50%', 0.50),
      ('75%', 0.75),
      ('Máx.', 1.0),
    ];

    return Row(
      children: options.map((item) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: item == options.last ? 0 : 8,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onSelected(item.$2),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: premiumFieldDecoration(radius: 14),
                  child: Text(
                    item.$1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.destaque,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PriceControlBox extends StatelessWidget {
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _PriceControlBox({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: premiumFieldDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PREÇO POR TOKEN',
            style: TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _RoundActionButton(
                icon: Icons.remove_rounded,
                onTap: onMinus,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textoPrincipal,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              _RoundActionButton(
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

class _RoundActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: enabled
          ? AppColors.card.withValues(alpha: 0.90)
          : AppColors.card.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: enabled
                ? AppColors.destaque
                : AppColors.textoMuitoFraco.withValues(alpha: 0.55),
            size: 21,
          ),
        ),
      ),
    );
  }
}