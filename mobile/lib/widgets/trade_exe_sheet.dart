import 'package:flutter/material.dart';

import '../models/balcao_model.dart';
import '../themes/app_theme.dart';
import '../screens/ordens/ordem_process.dart';

class TradeExecutionSheet extends StatelessWidget {
  final Oferta oferta;
  final ModoNegociacao modo;
  final List<Oferta> ofertasDisponiveis;

  const TradeExecutionSheet({
    super.key,
    required this.oferta,
    required this.modo,
    required this.ofertasDisponiveis,
  });

  bool get isCompra => modo == ModoNegociacao.compra;

  double get subtotal => oferta.preco * oferta.quantidade;

  double get taxa => subtotal * 0.004;

  double get totalFinal => isCompra ? subtotal + taxa : subtotal - taxa;

  double get precoMedio {
    final relacionadas = ofertasDisponiveis
        .where((item) => item.simbolo == oferta.simbolo)
        .toList();

    if (relacionadas.isEmpty) return oferta.preco;

    final soma = relacionadas.fold<double>(
      0,
          (total, item) => total + item.preco,
    );

    return soma / relacionadas.length;
  }

  @override
  Widget build(BuildContext context) {
    final accent = isCompra ? AppColors.destaque : AppColors.azul;
    final diferenca = precoMedio == 0
        ? 0
        : ((oferta.preco - precoMedio) / precoMedio) * 100;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.55,
      maxChildSize: 0.86,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: SingleChildScrollView(
            controller: controller,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              24,
              14,
              24,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _sheetHandle()),

                const SizedBox(height: 22),

                _header(accent),

                const SizedBox(height: 20),

                _infoCard(
                  title: 'Comparação de mercado',
                  children: [
                    _row(
                      'Preço da oferta',
                      'R\$ ${oferta.preco.toStringAsFixed(2)}',
                      highlighted: true,
                    ),
                    _row(
                      'Preço médio',
                      'R\$ ${precoMedio.toStringAsFixed(2)}',
                    ),
                    _row(
                      'Diferença',
                      '${diferenca >= 0 ? '+' : ''}${diferenca.toStringAsFixed(1)}%',
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                _infoCard(
                  title: 'Resumo da ordem',
                  children: [
                    _row('Quantidade', '${oferta.quantidade} tokens'),
                    _row('Subtotal', 'R\$ ${subtotal.toStringAsFixed(2)}'),
                    _row('Taxa simulada', 'R\$ ${taxa.toStringAsFixed(2)}'),
                    const Divider(color: AppColors.bordaClara, height: 24),
                    _row(
                      isCompra ? 'Total estimado' : 'Valor líquido',
                      'R\$ ${totalFinal.toStringAsFixed(2)}',
                      highlighted: true,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _confirmButton(context, accent),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetHandle() {
    return Container(
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.bordaMedia,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _header(Color accent) {
    return Row(
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
              oferta.simbolo,
              style: TextStyle(
                color: accent,
                fontSize: 13,
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
                oferta.empresa,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textoPrincipal,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isCompra
                    ? 'Revise sua ordem de compra'
                    : 'Revise sua ordem de venda',
                style: const TextStyle(
                  color: AppColors.textoMuitoFraco,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.campo,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.bordaClara,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
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
          title.toUpperCase(),
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

  Widget _row(
      String label,
      String value, {
        bool highlighted = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlighted
                  ? AppColors.textoPrincipal
                  : AppColors.textoFraco,
              fontSize: 13,
              fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: highlighted
                  ? AppColors.destaque
                  : AppColors.textoPrincipal,
              fontSize: highlighted ? 15 : 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmButton(BuildContext context, Color accent) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: isCompra
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
              color: accent.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.pop(context);

              Future.delayed(const Duration(milliseconds: 160), () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  enableDrag: false,
                  builder: (_) => OrderProcessingSheet(
                    oferta: oferta,
                    modo: modo,
                  ),
                );
              });
            },
            child: Center(
              child: Text(
                isCompra ? 'CONFIRMAR COMPRA' : 'CONFIRMAR VENDA',
                style: TextStyle(
                  color: isCompra
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
}