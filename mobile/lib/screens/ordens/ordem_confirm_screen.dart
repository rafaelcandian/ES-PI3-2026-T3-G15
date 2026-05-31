/* Victória Nobre - 25016398 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mescla_invest/widgets/shared/page_header.dart';
import 'package:mescla_invest/models/balcao_model.dart';
import 'package:mescla_invest/services/balcao_service.dart';
import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';
import 'package:mescla_invest/widgets/shared/app_button.dart';
import 'package:mescla_invest/widgets/shared/atmospheric_background.dart';
import 'package:mescla_invest/widgets/shared/info_row.dart';
import 'package:mescla_invest/widgets/shared/section_card.dart';

/* Hub de Efetivação Transacional (Transaction Settlement Hub).
   Responsável pela execução final da ordem, interagindo com o BalcaoService.
   Implementa a orquestração de chamadas assíncronas e a gestão de estados de feedback
   (Loading, Success, Failure) para garantir a integridade da percepção do usuário. */
class OrdemConfirmScreen extends StatefulWidget {
  final Oferta oferta;
  final ModoNegociacao modo;
  final double totalFinal;
  final double taxa;
  final bool atingiuMinimo;
  final bool compraDireto;

  const OrdemConfirmScreen({
    super.key,
    required this.oferta,
    required this.modo,
    required this.totalFinal,
    required this.taxa,
    this.atingiuMinimo = true,
    required this.compraDireto,
  });

  @override
  State<OrdemConfirmScreen> createState() => _OrdemConfirmScreenState();
}

class _OrdemConfirmScreenState extends State<OrdemConfirmScreen> {
  bool _concluida = false;
  String? _erro;

  bool get _isCompra => widget.modo == ModoNegociacao.compra;

  @override
  void initState() {
    super.initState();
    _executarOrdem();
  }

  /* Orquestrador de Chamadas de Serviço (Service Dispatcher).
     Encapsula a lógica de decisão sobre qual endpoint do backend invocar:
     1. Direct Purchase: Compra imediata da Startup (Mercado Primário).
     2. Existing Order Execution: Compra de oferta de outro usuário (Mercado Secundário).
     3. Order Creation: Lançamento de nova oferta Limit no balcão. */
  Future<void> _executarOrdem() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        throw Exception('Usuário não autenticado. Faça login novamente.');
      }

      String? erro;

      if (_isCompra) {
        if (widget.atingiuMinimo && widget.compraDireto) {
          erro = await BalcaoService().comprarDiretoDaStartup(
            startupId: widget.oferta.startupId,
            quantity: widget.oferta.quantidade,
            pricePerToken: widget.oferta.preco,
          );
        } else if (widget.oferta.id.trim().isNotEmpty) {
          erro = await BalcaoService().comprarOfertaVendaExistente(
            orderId: widget.oferta.id,
            quantity: widget.oferta.quantidade,
            totalFinal: widget.totalFinal,
            taxa: widget.taxa,
          );
        } else {
          erro = await BalcaoService().createPurchaseOffer(
            startupId: widget.oferta.startupId,
            quantity: widget.oferta.quantidade,
            pricePerToken: widget.oferta.preco,
          );
        }
      } else {
        erro = await BalcaoService().createSellOffer(
          startupId: widget.oferta.startupId,
          quantity: widget.oferta.quantidade,
          pricePerToken: widget.oferta.preco,
        );
      }

      if (erro != null) throw Exception(erro);

      if (!mounted) return;

      setState(() {
        _concluida = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /* Define dinamicamente le título de sucesso com base no tipo de operação realizada. */
  String _tituloConclusao() {
    if (_isCompra && widget.compraDireto && widget.atingiuMinimo) {
      return 'Investimento realizado!';
    }

    if (_isCompra && widget.oferta.id.trim().isNotEmpty) {
      return 'Compra realizada!';
    }

    return _isCompra
        ? 'Ordem de compra registrada!'
        : 'Ordem de venda registrada!';
  }

  String _subtituloConclusao() {
    if (_isCompra && widget.compraDireto && widget.atingiuMinimo) {
      return 'Seus tokens foram adquiridos com sucesso e a movimentação foi salva automaticamente na carteira.';
    }

    if (_isCompra && widget.oferta.id.trim().isNotEmpty) {
      return 'Os tokens da oferta selecionada foram comprados com sucesso e a movimentação foi salva na carteira.';
    }

    if (_isCompra) {
      return 'Sua ordem de compra foi postada no balcão. Ela só aparecerá no histórico da carteira quando for executada.';
    }

    return 'Sua ordem de venda foi registrada no balcão. Ela só aparecerá no histórico da carteira quando for executada.';
  }

  String get _tituloTela {
    if (_concluida) return _tituloConclusao();
    if (_erro != null) return 'Ordem não processada';
    return 'Organizando sua ordem...';
  }

  String get _subtituloTela {
    if (_concluida) return _subtituloConclusao();

    if (_erro != null) {
      return 'Não foi possível registrar a ordem. Verifique o erro abaixo.';
    }

    return 'Estamos validando os dados, calculando taxas e registrando sua ordem.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: Stack(
        children: [
          const AtmosphericBackground(),
          SafeArea(
            child: Column(
              children: [
                _ConfirmTopBar(concluida: _concluida),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _StatusIcon(concluida: _concluida, erro: _erro != null),
                        const SizedBox(height: 24),
                        PageHeader(
                          title: _tituloTela,
                          subtitle: _subtituloTela,
                          centered: true,
                          titleFontSize: 26,
                        ),
                        const SizedBox(height: 28),
                        _buildResumoCard(),
                        const SizedBox(height: 18),
                        _StepsCard(
                          concluida: _concluida,
                          erro: _erro != null,
                        ),
                        const SizedBox(height: 28),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _concluida
                              ? _buildActions()
                              : _erro != null
                              ? _buildErroMessage()
                              : const _WaitingMessage(),
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

  Widget _buildResumoCard() {
    return SectionCard(
      title: 'Resumo da ordem',
      child: Column(
        children: [
          InfoRow(
            label: 'Startup',
            value: widget.oferta.empresa,
            boxed: true,
          ),
          const SizedBox(height: 10),
          InfoRow(
            label: 'Ticker',
            value: widget.oferta.simbolo,
            boxed: true,
          ),
          const SizedBox(height: 10),
          InfoRow(
            label: 'Operação',
            value: _isCompra ? 'Compra' : 'Venda',
            boxed: true,
          ),
          const SizedBox(height: 10),
          InfoRow(
            label: 'Quantidade',
            value: '${widget.oferta.quantidade} tokens',
            boxed: true,
          ),
          const SizedBox(height: 10),
          InfoRow(
            label: 'Taxa simulada',
            value: 'R\$ ${widget.taxa.toStringAsFixed(2)}',
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
            value: 'R\$ ${widget.totalFinal.toStringAsFixed(2)}',
            destaque: true,
            boxed: true,
          ),
        ],
      ),
    );
  }

  Widget _buildErroMessage() {
    return Container(
      key: const ValueKey('erro'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _erro ?? 'Erro desconhecido.',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* Opções de navegação pós-transação: retornar ao catálogo ou conferir le portfólio. */
  Widget _buildActions() {
    return Column(
      key: const ValueKey('actions'),
      children: [
        AppButton.primary(
          label: 'Voltar às startups',
          icon: Icons.storefront_rounded,
          onTap: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/catalogo',
              (route) => false,
            );
          },
        ),
        const SizedBox(height: 12),
        AppButton.outline(
          label: 'Ver carteira',
          icon: Icons.account_balance_wallet_rounded,
          onTap: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/carteira',
              (route) => false,
            );
          },
        ),
      ],
    );
  }
}

class _ConfirmTopBar extends StatelessWidget {
  final bool concluida;

  const _ConfirmTopBar({
    required this.concluida,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: concluida ? null : () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: concluida
                  ? AppColors.textoMuitoFraco.withValues(alpha: 0.55)
                  : AppColors.destaque,
              size: 20,
            ),
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final bool concluida;
  final bool erro;

  const _StatusIcon({
    required this.concluida,
    required this.erro,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = const _LoadingIcon();

    if (concluida) {
      child = const _CheckIcon();
    } else if (erro) {
      child = const _ErrorIcon();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: child,
    );
  }
}

class _LoadingIcon extends StatelessWidget {
  const _LoadingIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('loading'),
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.card,
        border: Border.all(
          color: AppColors.bordaClara,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 12),
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

class _CheckIcon extends StatelessWidget {
  const _CheckIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('check'),
      width: 88,
      height: 88,
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
            color: AppColors.destaque.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.check_rounded,
        color: AppColors.fundo,
        size: 48,
      ),
    );
  }
}

class _ErrorIcon extends StatelessWidget {
  const _ErrorIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('error'),
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red.withValues(alpha: 0.10),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.12),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.close_rounded,
        color: Colors.redAccent,
        size: 46,
      ),
    );
  }
}

class _WaitingMessage extends StatelessWidget {
  const _WaitingMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('waiting'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: premiumFieldDecoration(radius: 18),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              color: AppColors.destaque,
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Aguarde alguns instantes...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/* Widget de Visualização de Fluxo (Progress Tracker).
   Implementa uma checklist visual das etapas lógicas da transação, mitigando a 
   ansiedade do usuário durante operações de I/O de rede e processamento em nuvem. */
class _StepsCard extends StatelessWidget {
  final bool concluida;
  final bool erro;

  const _StepsCard({
    required this.concluida,
    required this.erro,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Processamento',
      child: Column(
        children: [
          _StepRow(
            label: 'Validando saldo ou ativos disponíveis',
            done: concluida,
            error: erro,
          ),
          const SizedBox(height: 10),
          _StepRow(
            label: 'Calculando taxa simulada',
            done: concluida,
            error: erro,
          ),
          const SizedBox(height: 10),
          _StepRow(
            label: 'Registrando movimentação na carteira',
            done: concluida,
            error: erro,
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final bool done;
  final bool error;

  const _StepRow({
    required this.label,
    required this.done,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final color = error
        ? Colors.redAccent
        : done
        ? AppColors.destaque
        : AppColors.bordaClara;

    return Container(
      decoration: premiumFieldDecoration(radius: 16),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.destaque : AppColors.campo,
              border: Border.all(
                color: color,
              ),
            ),
            child: done
                ? const Icon(
              Icons.check_rounded,
              size: 16,
              color: AppColors.fundo,
            )
                : error
                ? const Icon(
              Icons.close_rounded,
              size: 15,
              color: Colors.redAccent,
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
      ),
    );
  }
}
