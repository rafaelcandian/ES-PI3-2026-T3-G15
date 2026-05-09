import 'dart:async';

import 'package:flutter/material.dart';
import '../models/balcao_model.dart';
import '../screens/auth/app_theme.dart';

class OrderProcessingSheet extends StatefulWidget {
  final Oferta oferta;
  final ModoNegociacao modo;

  const OrderProcessingSheet({
    super.key,
    required this.oferta,
    required this.modo,
  });

  @override
  State<OrderProcessingSheet> createState() => _OrderProcessingSheetState();
}

class _OrderProcessingSheetState extends State<OrderProcessingSheet> {
  bool _completed = false;

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        _completed = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCompra = widget.modo == ModoNegociacao.compra;
    final actionLabel = isCompra ? 'compra' : 'venda';

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 24,
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

          const SizedBox(height: 28),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _completed
                ? Container(
              key: const ValueKey('check'),
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    AppColors.destaqueClaro,
                    AppColors.destaqueEscuro,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.destaque.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.card,
                size: 42,
              ),
            )
                : const SizedBox(
              key: ValueKey('loading'),
              width: 76,
              height: 76,
              child: CircularProgressIndicator(
                color: AppColors.destaque,
                strokeWidth: 3,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            _completed ? 'Ordem concluída!' : 'Organizando sua ordem...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.destaque,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            _completed
                ? 'Sua ordem de $actionLabel de ${widget.oferta.quantidade} tokens ${widget.oferta.simbolo} foi registrada com sucesso.'
                : 'Estamos validando os tokens, calculando a taxa simulada e registrando a ordem no balcão.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textoFraco,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 26),

          _StepRow(
            label: 'Validando dados da ordem',
            completed: _completed,
          ),
          const SizedBox(height: 10),
          _StepRow(
            label: 'Conferindo saldo ou ativos disponíveis',
            completed: _completed,
          ),
          const SizedBox(height: 10),
          _StepRow(
            label: 'Registrando negociação simulada',
            completed: _completed,
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.destaqueClaro,
                    AppColors.destaqueEscuro,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _completed ? () => Navigator.pop(context) : null,
                  child: Center(
                    child: Text(
                      _completed ? 'Voltar ao balcão' : 'Aguarde...',
                      style: TextStyle(
                        color: AppColors.card.withOpacity(
                          _completed ? 1 : 0.55,
                        ),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final bool completed;

  const _StepRow({
    required this.label,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed
                ? AppColors.destaque
                : AppColors.campo,
            border: Border.all(
              color: completed
                  ? AppColors.destaque
                  : AppColors.bordaClara,
            ),
          ),
          child: completed
              ? const Icon(
            Icons.check_rounded,
            size: 15,
            color: AppColors.card,
          )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textoFraco,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}