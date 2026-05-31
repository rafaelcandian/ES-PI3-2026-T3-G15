/* Victória Nobre - 25016398 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mescla_invest/widgets/shared/page_header.dart';
import 'package:mescla_invest/models/balcao_model.dart';
import 'package:mescla_invest/services/carteira_service.dart';
import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/widgets/shared/app_button.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';
import 'package:mescla_invest/widgets/shared/app_snackbar.dart';
import 'package:mescla_invest/widgets/shared/atmospheric_background.dart';
import 'package:mescla_invest/widgets/shared/info_row.dart';
import 'package:mescla_invest/widgets/shared/section_card.dart';
import 'package:mescla_invest/widgets/shared/ticker_box.dart';

import 'ordem_confirm_screen.dart';

/* Motor de Execução de Ordens (Trade Execution Engine).
   Responsável pela parametrização de ordens Limit (Preço Fixo). Implementa a lógica 
   de 'Pre-trade Risk Management', validando saldo, estoque de tokens e limites de 
   investimento antes da submissão ao motor de matching do backend. */
class OrdemExeScreen extends StatefulWidget {
  final Oferta oferta;
  final ModoNegociacao modo;
  final List<Oferta> ofertasDisponiveis;
  final double investimentoMinimo;
  final bool compraDireto;
  final int? quantidadeMaximaUsuario;

  const OrdemExeScreen({
    super.key,
    required this.oferta,
    required this.modo,
    required this.ofertasDisponiveis,
    this.investimentoMinimo = 0.0,
    this.compraDireto = false,
    this.quantidadeMaximaUsuario,
  });

  @override
  State<OrdemExeScreen> createState() => _OrdemExeScreenState();
}

class _OrdemExeScreenState extends State<OrdemExeScreen> {
  late int _quantidade;
  late double _preco;
  late final TextEditingController _quantidadeController;
  late final TextEditingController _precoController;

  double _precoMedioReal = 0.0;

  /// Saldo em reais do usuário, carregado via CarteiraService.
  double? _saldoUsuario;

  bool get _isCompra => widget.modo == ModoNegociacao.compra;

  /* Motor de Cálculo de Poder de Compra (Buying Power Engine).
     Determina dinamicamente a quantidade máxima de tokens (Floor do quociente Saldo / Preço) 
     para prevenir rejeições por falta de fundos na camada de serviço. */
  int get _quantidadeMaximaPorSaldo {
    if (_saldoUsuario == null || _preco <= 0) return 0;
    return (_saldoUsuario! / _preco).floor();
  }

  /// Indica se le saldo é insuficiente para comprar ao menos 1 token.
  bool get _saldoInsuficiente {
    return _isCompra && _saldoUsuario != null && _quantidadeMaximaPorSaldo <= 0;
  }

  double get _subtotal => _quantidade * _preco;

  double get _taxa => _subtotal * 0.004;

  double get _totalFinal => _isCompra ? _subtotal + _taxa : _subtotal - _taxa;

  double get _precoReferencia {
    return _precoMedioReal > 0 ? _precoMedioReal : widget.oferta.preco;
  }

  double get _diferenca {
    if (_precoReferencia == 0) return 0;
    return ((_preco - _precoReferencia) / _precoReferencia) * 100;
  }

  double get _precoMinimoPermitido {
    if (_isCompra) return widget.oferta.minBuyPrice;
    return 0.10;
  }

  bool get _precoAbaixoDoMinimo {
    return _isCompra && _preco < widget.oferta.minBuyPrice;
  }

  /* Define le teto da operação respeitando saldo, estoque e tipo de ordem. */
  int get _maximoQuantidade {
    if (!_isCompra && widget.quantidadeMaximaUsuario != null) {
      return widget.quantidadeMaximaUsuario!;
    }

    // No modo compra, limita pelo saldo disponível do usuário.
    if (_isCompra && _saldoUsuario != null) {
      final limitePorSaldo = _quantidadeMaximaPorSaldo;
      return limitePorSaldo.clamp(0, widget.oferta.quantidade);
    }

    return widget.oferta.quantidade;
  }

  @override
  void initState() {
    super.initState();

    // Inicia com 1 token se houver disponibilidade, caso contrário 0.
    _quantidade = _maximoQuantidade > 0 ? 1 : 0;
    _preco = widget.oferta.preco;

    _quantidadeController = TextEditingController(text: _quantidade.toString());
    _precoController = TextEditingController(text: _preco.toStringAsFixed(2));

    _precoController.addListener(_atualizarPrecoDigitado);

    _calcularPrecoMedioReal().then((preco) {
      if (!mounted) return;
      setState(() => _precoMedioReal = preco);
    });

    // Busca le saldo do usuário para limitar a compra.
    _carregarSaldoUsuario();
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _precoController
      ..removeListener(_atualizarPrecoDigitado)
      ..dispose();
    super.dispose();
  }

  Future<void> _carregarSaldoUsuario() async {
    try {
      final saldo = await CarteiraService().getBalance();
      if (!mounted) return;
      setState(() => _saldoUsuario = saldo);
    } catch (_) {
      // Em caso de erro, mantém _saldoUsuario como null
      // e a tela usará apenas le limite da oferta.
    }
  }

  /* Busca le histórico para oferecer uma base de comparação de preço ao usuário. */
  Future<double> _calcularPrecoMedioReal() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return widget.oferta.preco;

      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('buyerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      final transacoesDaStartup = snapshot.docs.where((doc) {
        return doc.data()['startupId'] == widget.oferta.startupId;
      }).toList();

      if (transacoesDaStartup.isEmpty) return widget.oferta.preco;

      final soma = transacoesDaStartup.fold<double>(0, (total, doc) {
        final price = (doc.data()['pricePerToken'] as num?)?.toDouble() ?? 0;
        return total + price;
      });

      return soma / transacoesDaStartup.length;
    } catch (_) {
      return widget.oferta.preco;
    }
  }

  /* Sincroniza a entrada de texto do preço com le estado interno do componente. */
  void _atualizarPrecoDigitado() {
    final texto = _precoController.text.replaceAll(',', '.');
    final valor = double.tryParse(texto);

    if (valor == null || valor <= 0 || valor == _preco) return;

    setState(() {
      _preco = valor;

      // Recalcula le máximo ao alterar preço (afeta limite por saldo).
      final novoMaximo = _maximoQuantidade;
      if (_quantidade > novoMaximo) {
        _quantidade = novoMaximo;
        _atualizarControllerQuantidade(novoMaximo);
      }
    });
  }

  void _atualizarQuantidade(String value) {
    final maximo = _maximoQuantidade;

    if (value.isEmpty) {
      setState(() => _quantidade = 0);
      return;
    }

    final quantidadeDigitada = int.tryParse(value) ?? 0;
    final quantidadeAjustada = quantidadeDigitada.clamp(0, maximo).toInt();

    if (quantidadeDigitada != quantidadeAjustada) {
      _atualizarControllerQuantidade(quantidadeAjustada);
    }

    setState(() => _quantidade = quantidadeAjustada);
  }

  void _alterarQuantidade(int novaQuantidade) {
    final maximo = _maximoQuantidade;
    final quantidadeAjustada = novaQuantidade.clamp(0, maximo).toInt();

    HapticFeedback.selectionClick();

    setState(() {
      _quantidade = quantidadeAjustada;
      _atualizarControllerQuantidade(quantidadeAjustada);
    });
  }

  void _selecionarPercentual(double percentual) {
    final maximo = _maximoQuantidade;

    if (maximo <= 0) {
      AppSnackBar.show(
        context,
        message: _saldoInsuficiente
            ? 'Saldo insuficiente para esta compra.'
            : 'Esta oferta não possui tokens disponíveis.',
        error: true,
      );
      return;
    }

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
      _preco = (_preco + delta).clamp(_precoMinimoPermitido, 999999);
      _precoController.text = _preco.toStringAsFixed(2);
      _precoController.selection = TextSelection.fromPosition(
        TextPosition(offset: _precoController.text.length),
      );

      // Recalcula le máximo ao alterar preço (afeta limite por saldo).
      final novoMaximo = _maximoQuantidade;
      if (_quantidade > novoMaximo) {
        _quantidade = novoMaximo;
        _atualizarControllerQuantidade(novoMaximo);
      }
    });
  }

  /* Algoritmo de Validação Final (Pre-submission Validation).
     Realiza o sanity check final dos parâmetros:
     1. Solvência: Saldo >= (Preço * Quantidade) + Taxas.
     2. Conformidade: Preço >= Preço Mínimo da Startup (Price Floor).
     3. Liquidez: Quantidade <= Oferta Disponível. */
  void _confirmarOrdem() {
    if (_saldoInsuficiente) {
      AppSnackBar.show(
        context,
        message: 'Saldo insuficiente para esta compra.',
        error: true,
      );
      return;
    }

    if (_quantidade <= 0) {
      AppSnackBar.show(
        context,
        message: 'Informe uma quantidade válida de tokens.',
        error: true,
      );
      return;
    }

    if (_quantidade > _maximoQuantidade) {
      AppSnackBar.show(
        context,
        message:
        'A quantidade máxima disponível é $_maximoQuantidade tokens.',
        error: true,
      );
      return;
    }

    if (_precoAbaixoDoMinimo) {
      AppSnackBar.show(
        context,
        message:
        'O preço mínimo de compra desta startup é R\$ ${widget.oferta.minBuyPrice.toStringAsFixed(2)}.',
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
      startupId: widget.oferta.startupId,
      id: widget.oferta.id,
      userId: widget.oferta.userId,
      createdAt: widget.oferta.createdAt,
      isStartup: widget.oferta.isStartup,
      minBuyPrice: widget.oferta.minBuyPrice,
    );

    final totalOrdem = _quantidade * _preco;
    final atingiuMinimo =
        !widget.compraDireto || totalOrdem >= widget.investimentoMinimo;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrdemConfirmScreen(
          oferta: ofertaFinal,
          modo: widget.modo,
          totalFinal: _totalFinal,
          taxa: _taxa,
          atingiuMinimo: atingiuMinimo,
          compraDireto: widget.compraDireto,
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
                const _OrderTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PageHeader(
                          title: _isCompra ? 'Comprar tokens' : 'Vender tokens',
                          subtitle: 'Revise os detalhes da operação antes de confirmar.',
                        ),
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
                        if (_saldoInsuficiente) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.30),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Saldo insuficiente para esta compra.',
                                    style: TextStyle(
                                      color: Colors.redAccent.withValues(alpha: 0.90),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        AppButton.primary(
                          label: _saldoInsuficiente
                              ? 'Saldo insuficiente'
                              : 'Confirmar $actionLabel',
                          icon: _isCompra
                              ? Icons.shopping_bag_rounded
                              : Icons.sell_rounded,
                          onTap: _saldoInsuficiente
                              ? null
                              : _confirmarOrdem,
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
                  value: 'R\$ ${_precoReferencia.toStringAsFixed(2)}',
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
          if (_isCompra) ...[
            const SizedBox(height: 10),
            _MarketMetricTile(
              label: 'Preço mínimo de compra',
              value: 'R\$ ${widget.oferta.minBuyPrice.toStringAsFixed(2)}',
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderConfiguration() {
    return SectionCard(
      title: 'Configuração da ordem',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuantityControlBox(
            controller: _quantidadeController,
            quantidade: _quantidade,
            maximo: _maximoQuantidade,
            onChanged: _atualizarQuantidade,
            onMinus: () {
              if (_quantidade > 0) _alterarQuantidade(_quantidade - 1);
            },
            onPlus: () {
              if (_quantidade < _maximoQuantidade) {
                _alterarQuantidade(_quantidade + 1);
              }
            },
          ),
          const SizedBox(height: 12),
          _QuickAmountButtons(onSelected: _selecionarPercentual),
          const SizedBox(height: 14),
          _PriceControlBox(
            controller: _precoController,
            isCompra: _isCompra,
            minBuyPrice: widget.oferta.minBuyPrice,
            precoAbaixoDoMinimo: _precoAbaixoDoMinimo,
            onMinus: () => _alterarPreco(-0.10),
            onPlus: () => _alterarPreco(0.10),
          ),
        ],
      ),
    );
  }

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
          const Divider(color: AppColors.bordaClara),
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

class _OrderTopBar extends StatelessWidget {
  const _OrderTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
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
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

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
          TickerBox(simbolo: oferta.simbolo, size: 58),
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
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${oferta.quantidade} tokens disponíveis • Spread ${oferta.spread.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  'Preço unitário: R\$ ${preco.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.destaque,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.destaque.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.bordaDestaque),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.destaque, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.destaque,
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
        border: Border.all(color: AppColors.bordaDestaque),
      )
          : premiumFieldDecoration(radius: 18),
      child: Column(
        crossAxisAlignment:
        fullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: destaque ? AppColors.destaque : Colors.white,
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
          Text(
            'Quantidade',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Você possui até $maximo tokens disponíveis para esta ordem.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontWeight: FontWeight.w500,
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: onChanged,
                    cursorColor: AppColors.destaque,
                    style: const TextStyle(
                      color: Colors.white,
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
            padding: EdgeInsets.only(right: item == options.last ? 0 : 8),
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
  final TextEditingController controller;
  final bool isCompra;
  final double minBuyPrice;
  final bool precoAbaixoDoMinimo;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _PriceControlBox({
    required this.controller,
    required this.isCompra,
    required this.minBuyPrice,
    required this.precoAbaixoDoMinimo,
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
          Text(
            'Preço por token',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _RoundActionButton(icon: Icons.remove_rounded, onTap: onMinus),
              Expanded(
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  cursorColor: AppColors.destaque,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              _RoundActionButton(icon: Icons.add_rounded, onTap: onPlus),
            ],
          ),
          if (isCompra) ...[
            const SizedBox(height: 8),
            Text(
              precoAbaixoDoMinimo
                  ? 'Preço abaixo do mínimo permitido: R\$ ${minBuyPrice.toStringAsFixed(2)}.'
                  : 'Preço mínimo de compra: R\$ ${minBuyPrice.toStringAsFixed(2)}.',
              style: TextStyle(
                color: precoAbaixoDoMinimo ? Colors.redAccent : Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
