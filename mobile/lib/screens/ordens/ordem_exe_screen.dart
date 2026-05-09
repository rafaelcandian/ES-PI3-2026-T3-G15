import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/balcao_model.dart';
import '../auth/app_theme.dart';
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

    _quantidade = widget.oferta.quantidade;
    _preco = widget.oferta.preco;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isCompra ? AppColors.destaque : AppColors.azul;

    return Scaffold(
      backgroundColor: AppColors.fundoEscuro,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(accent),

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
              color: AppColors.textoPrincipal,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _isCompra ? 'Executar compra' : 'Executar venda',
            style: const TextStyle(
              color: AppColors.destaque,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: _isCompra ? 'ORDEM DE COMPRA' : 'ORDEM DE VENDA',
        ),
        const SizedBox(height: 14),
        Text(
          _isCompra ? 'Comprar tokens' : 'Vender tokens',
          style: const TextStyle(
            color: AppColors.textoPrincipal,
            fontSize: 28,
            fontWeight: FontWeight.w800,
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
          ),
        ),
      ],
    );
  }

  Widget _buildResumoStartup(Color accent) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
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
        _InfoRow(
          label: 'Preço médio',
          value: 'R\$ ${_precoMedio.toStringAsFixed(2)}',
        ),
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
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'CONFIGURAÇÃO DA ORDEM'),
          const SizedBox(height: 18),

          _ControlBox(
            label: 'Quantidade de tokens',
            value: _quantidade.toString(),
            onMinus: () {
              if (_quantidade <= 1) return;

              HapticFeedback.selectionClick();

              setState(() {
                _quantidade--;
              });
            },
            onPlus: () {
              if (_quantidade >= widget.oferta.quantidade) return;

              HapticFeedback.selectionClick();

              setState(() {
                _quantidade++;
              });
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
        _InfoRow(
          label: 'Taxa simulada',
          value: 'R\$ ${_taxa.toStringAsFixed(2)}',
        ),
        const Divider(
          color: AppColors.bordaClara,
          height: 22,
        ),
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
                  color: _isCompra
                      ? AppColors.card
                      : AppColors.textoPrincipal,
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppColors.bordaClara,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.30),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}

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
      decoration: BoxDecoration(
        color: AppColors.campo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.bordaClara,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title.toUpperCase()),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: destaque ? AppColors.textoPrincipal : AppColors.textoFraco,
              fontSize: destaque ? 14 : 13,
              fontWeight: destaque ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: destaque ? AppColors.destaque : AppColors.textoPrincipal,
              fontSize: destaque ? 16 : 13,
              fontWeight: FontWeight.w900,
            ),
          ),
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
      decoration: BoxDecoration(
        color: AppColors.campo,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.bordaClara,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 10,
              fontWeight: FontWeight.w800,
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
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            color: AppColors.destaque,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
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
          title,
          style: const TextStyle(
            color: AppColors.destaque,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}