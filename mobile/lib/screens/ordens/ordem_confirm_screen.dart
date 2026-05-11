import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mescla_invest/widgets/premium_ui.dart';

import '../../models/balcao_model.dart';
import '../../themes/app_theme.dart';

class OrdemConfirmScreen extends StatefulWidget {
  final Oferta oferta;
  final ModoNegociacao modo;
  final double totalFinal;
  final double taxa;

  const OrdemConfirmScreen({
    super.key,
    required this.oferta,
    required this.modo,
    required this.totalFinal,
    required this.taxa,
  });

  @override
  State<OrdemConfirmScreen> createState() => _OrdemConfirmScreenState();
}

class _OrdemConfirmScreenState extends State<OrdemConfirmScreen> {
  bool _concluida = false;
  Timer? _timer;

  bool get _isCompra => widget.modo == ModoNegociacao.compra;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        _concluida = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _concluida ? 'Ordem concluída!' : 'Organizando sua ordem...';

    final subtitulo = _concluida
        ? 'Sua ${_isCompra ? 'compra' : 'venda'} de ${widget.oferta.quantidade} tokens ${widget.oferta.simbolo} foi registrada com sucesso.'
        : 'Estamos validando os dados, calculando taxas e registrando sua ordem simulada.';

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
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _concluida
                              ? _buildCheckIcon()
                              : _buildLoadingIcon(),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          titulo,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.destaque,
                            fontSize: 25,
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
                        _StepsCard(
                          concluida: _concluida,
                        ),
                        const SizedBox(height: 28),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _concluida
                              ? _buildActions()
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: _concluida ? null : () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _concluida
                  ? AppColors.textoMuitoFraco.withOpacity(0.55)
                  : AppColors.destaque,
              size: 20,
            ),
          ),
          const Expanded(
            child: SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIcon() {
    return Container(
      key: const ValueKey('loading'),
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.card,
        border: Border.all(
          color: AppColors.bordaClara,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.32),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: const CircularProgressIndicator(
        color: AppColors.destaque,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildCheckIcon() {
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
            color: AppColors.destaque.withOpacity(0.28),
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

  Widget _buildResumoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: premiumCardDecoration(
        radius: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumHeaderEyebrow(
            text: 'RESUMO DA ORDEM',
          ),
          const SizedBox(height: 16),
          _ResumoRow(
            label: 'Startup',
            value: widget.oferta.empresa,
          ),
          const SizedBox(height: 10),
          _ResumoRow(
            label: 'Ticker',
            value: widget.oferta.simbolo,
          ),
          const SizedBox(height: 10),
          _ResumoRow(
            label: 'Operação',
            value: _isCompra ? 'Compra' : 'Venda',
          ),
          const SizedBox(height: 10),
          _ResumoRow(
            label: 'Quantidade',
            value: '${widget.oferta.quantidade} tokens',
          ),
          const SizedBox(height: 10),
          _ResumoRow(
            label: 'Taxa simulada',
            value: 'R\$ ${widget.taxa.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            width: double.infinity,
            color: AppColors.bordaClara,
          ),
          const SizedBox(height: 14),
          _TotalBox(
            label: _isCompra ? 'Total estimado' : 'Valor líquido',
            value: 'R\$ ${widget.totalFinal.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      key: const ValueKey('actions'),
      children: [
        _buildPrimaryButton(
          label: 'Voltar ao balcão',
          onTap: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/balcao',
                  (route) => false,
            );
          },
        ),
        const SizedBox(height: 12),
        _buildSecondaryButton(
          label: 'Ver carteira',
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

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
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
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.destaque.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.fundo,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textoPrincipal,
          side: const BorderSide(
            color: AppColors.bordaClara,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: AppColors.card.withOpacity(0.35),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
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

// ===================== WAITING =====================

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
      decoration: premiumFieldDecoration(
        radius: 18,
      ),
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

// ===================== STEPS =====================

class _StepsCard extends StatelessWidget {
  final bool concluida;

  const _StepsCard({
    required this.concluida,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: premiumCardDecoration(
        radius: 22,
      ),
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
            label: 'Registrando ordem no balcão',
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
      decoration: premiumFieldDecoration(
        radius: 16,
      ),
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

// ===================== RESUMO =====================

class _ResumoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResumoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: premiumFieldDecoration(
        radius: 16,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textoFraco,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textoPrincipal,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalBox extends StatelessWidget {
  final String label;
  final String value;

  const _TotalBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.destaque.withOpacity(0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.bordaDestaque,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.destaque.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textoPrincipal,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.destaque,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}