/* Gabriel Benevides Bosso- 24016398 */
/* Guilherme Henrique Moreira - 25006702 */

//Ordens foram feitas por Guilherme e Gabriel.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mescla_invest/models/balcao_model.dart';
import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';
import 'package:mescla_invest/widgets/shared/app_button.dart';

/* Bottom sheet de processamento da ordem: Fornece feedback visual (Loading e Success) 
   para operações assíncronas de backend. É crucial para manter a UX fluida enquanto 
   as Cloud Functions processam os dados financeiros complexos. */
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
  Timer? _timer;

  bool get _isCompra => widget.modo == ModoNegociacao.compra;

  @override
  void initState() {
    super.initState();

    /* Simula le tempo de processamento da rede para feedback visual ao usuário. */
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _completed = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _titulo {
    return _completed ? 'Ordem concluída!' : 'Organizando sua ordem...';
  }

  String get _descricao {
    final actionLabel = _isCompra ? 'compra' : 'venda';

    if (_completed) {
      return 'Sua ordem de $actionLabel de ${widget.oferta.quantidade} tokens ${widget.oferta.simbolo} foi registrada com sucesso.';
    }

    return 'Estamos validando os tokens, calculando a taxa simulada e registrando a ordem no balcão.';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 14,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: const Border(
              top: BorderSide(color: AppColors.bordaClara, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 34,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 28),
              _StatusIcon(completed: _completed),
              const SizedBox(height: 24),
              Text(
                _titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.destaque,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _descricao,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 26),
              _StepsList(completed: _completed),
              const SizedBox(height: 28),
              AppButton.primary(
                label: _completed ? 'Voltar ao balcão' : 'Aguarde...',
                loading: !_completed,
                onTap: _completed ? () => Navigator.pop(context) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.bordaMedia,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

/* Alterna entre le estado de carregamento e le check de conclusão. */
class _StatusIcon extends StatelessWidget {
  final bool completed;

  const _StatusIcon({
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: completed ? const _CheckIcon() : const _LoadingIcon(),
    );
  }
}

class _CheckIcon extends StatelessWidget {
  const _CheckIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
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
            color: AppColors.destaque.withValues(alpha: 0.26),
            blurRadius: 26,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: const Icon(
        Icons.check_rounded,
        color: AppColors.fundo,
        size: 42,
      ),
    );
  }
}

class _LoadingIcon extends StatelessWidget {
  const _LoadingIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('loading'),
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.campo,
        border: Border.all(color: AppColors.bordaClara),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const CircularProgressIndicator(
        color: AppColors.destaque,
        strokeWidth: 3,
      ),
    );
  }
}

/* Lista informativa das validações internas sendo realizadas. */
class _StepsList extends StatelessWidget {
  final bool completed;

  const _StepsList({
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Validando dados da ordem',
      'Conferindo saldo ou ativos disponíveis',
      'Registrando negociação simulada',
    ];

    return Container(
      decoration: premiumFieldDecoration(radius: 18),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: List.generate(steps.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == steps.length - 1 ? 0 : 10,
            ),
            child: _StepRow(label: steps[index], completed: completed),
          );
        }),
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
            color: completed ? AppColors.destaque : AppColors.campo,
            border: Border.all(
              color: completed ? AppColors.destaque : AppColors.bordaClara,
            ),
          ),
          child: completed
              ? const Icon(
            Icons.check_rounded,
            size: 15,
            color: AppColors.fundo,
          )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
