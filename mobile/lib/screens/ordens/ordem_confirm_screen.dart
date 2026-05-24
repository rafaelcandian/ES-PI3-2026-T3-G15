import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mescla_invest/models/balcao_model.dart';
import 'package:mescla_invest/services/balcao_service.dart';
import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';
import 'package:mescla_invest/widgets/shared/atmospheric_background.dart';
import 'package:mescla_invest/widgets/shared/gradient_button.dart';
import 'package:mescla_invest/widgets/shared/info_row.dart';
import 'package:mescla_invest/widgets/shared/outline_button.dart' as shared;
import 'package:mescla_invest/widgets/shared/section_card.dart';

/// Tela de processamento e conclusão da ordem.
///
/// Simula a validação da operação e, após alguns segundos,
/// exibe as ações finais para voltar ao Balcão ou abrir a Carteira.
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
  // mensagem de erro retornada pelo BalcaoService (null = sem erro)
  String? _erro;
  bool _loading = true;

  bool get _isCompra => widget.modo == ModoNegociacao.compra;

  @override
  void initState() {
    super.initState();

    // Chama o BalcaoService real assim que a tela monta
    _executarOrdem();
  }

  /// Executa a ordem usando o backend.
  ///
  /// Fluxos cobertos:
  /// - compra direta da startup;
  /// - criação de oferta de compra no balcão;
  /// - criação de oferta de venda no balcão.
  Future<void> _executarOrdem() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        throw Exception('Usuário não autenticado. Faça login novamente.');
      }

      String? erro;

      if (_isCompra) {
        if (widget.atingiuMinimo == true && widget.compraDireto == true) {
          erro = await BalcaoService().comprarDiretoDaStartup(
            startupId: widget.oferta.startupId,
            quantity: widget.oferta.quantidade,
            pricePerToken: widget.oferta.preco,
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
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _tituloConclusao() {
    if (_isCompra && widget.compraDireto && widget.atingiuMinimo) {
      return 'Investimento realizado!';
    }

    return _isCompra ? 'Ordem de compra registrada!' : 'Ordem de venda registrada!';
  }

  String _subtituloConclusao() {
    if (_isCompra && widget.compraDireto && widget.atingiuMinimo) {
      return 'Seus tokens foram adquiridos com sucesso e a movimentação foi salva automaticamente na carteira.';
    }

    if (_isCompra) {
      return 'Sua ordem de compra foi postada no balcão. Ela só aparecerá no histórico da carteira quando for executada.';
    }

    return 'Sua ordem de venda foi registrada no balcão. Ela só aparecerá no histórico da carteira quando for executada.';
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _concluida
        ? _tituloConclusao()
        : _erro != null
            ? 'Ordem não processada'
            : 'Organizando sua ordem...';

    final subtitulo = _concluida
        ? _subtituloConclusao()
        : _erro != null
            ? 'Não foi possível registrar a ordem. Verifique o erro abaixo.'
            : 'Estamos validando os dados, calculando taxas e registrando sua ordem.';

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
                        _StatusIcon(concluida: _concluida),
                        const SizedBox(height: 24),
                        Text(
                          titulo,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.destaque,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            subtitulo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textoFraco,
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildResumoCard(),
                        const SizedBox(height: 18),
                        _StepsCard(concluida: _concluida),
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

  /// Card com os principais dados da ordem executada.
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

  /// Widget exibido quando o backend retorna um erro.
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

  Widget _buildActions() {
    return Column(
      key: const ValueKey('actions'),
      children: [
        GradientButton(
          label: 'Voltar às startups',
          icon: Icons.storefront_rounded,
          height: 54,
          radius: 18,
          onTap: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/catalogo',
                  (route) => false,
            );
          },
        ),
        const SizedBox(height: 12),
        shared.OutlineButton(
          label: 'Ver carteira',
          icon: Icons.account_balance_wallet_rounded,
          height: 52,
          radius: 18,
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

  const _StatusIcon({
    required this.concluida,
  });



  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: concluida ? const _CheckIcon() : const _LoadingIcon(),
    );
  }
}

class _LoadingIcon extends StatelessWidget {
  const _LoadingIcon({
    super.key,
  });



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
  const _CheckIcon({
    super.key,
  });



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

/// Mensagem exibida durante a simulação de processamento.
class _WaitingMessage extends StatelessWidget {
  const _WaitingMessage({
    super.key,
  });



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
              color: AppColors.textoMuitoFraco,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Etapas visuais do processamento da ordem.
class _StepsCard extends StatelessWidget {
  final bool concluida;

  const _StepsCard({
    required this.concluida,
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
          ),
          const SizedBox(height: 10),
          _StepRow(
            label: 'Calculando taxa simulada',
            done: concluida,
          ),
          const SizedBox(height: 10),
          _StepRow(
            label: 'Registrando movimentação na carteira',
            done: concluida,
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final bool done;

  const _StepRow({
    required this.label,
    required this.done,
  });



  @override
  Widget build(BuildContext context) {
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
                color: done ? AppColors.destaque : AppColors.bordaClara,
              ),
            ),
            child: done
                ? const Icon(
              Icons.check_rounded,
              size: 16,
              color: AppColors.fundo,
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
