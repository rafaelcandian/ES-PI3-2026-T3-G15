import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/balcao_model.dart';
import '../auth/app_theme.dart';

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

  bool get _isCompra => widget.modo == ModoNegociacao.compra;

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        _concluida = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _concluida ? 'Ordem concluída!' : 'Organizando sua ordem...';

    final subtitulo = _concluida
        ? 'Sua ${_isCompra ? 'compra' : 'venda'} de ${widget.oferta.quantidade} tokens ${widget.oferta.simbolo} foi registrada com sucesso.'
        : 'Estamos validando os dados, calculando taxas e registrando sua ordem simulada.';

    return Scaffold(
      backgroundColor: AppColors.fundoEscuro,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            children: [
              const Spacer(),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _concluida ? _buildCheckIcon() : _buildLoadingIcon(),
              ),

              const SizedBox(height: 28),

              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.destaque,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                subtitulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textoFraco,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              _buildResumoCard(),

              const SizedBox(height: 26),

              _buildStep(
                'Validando saldo ou ativos disponíveis',
                _concluida,
              ),
              const SizedBox(height: 12),
              _buildStep(
                'Calculando taxa simulada',
                _concluida,
              ),
              const SizedBox(height: 12),
              _buildStep(
                'Registrando ordem no balcão',
                _concluida,
              ),

              const Spacer(),

              if (_concluida) ...[
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
              ] else
                const Text(
                  'Aguarde alguns instantes...',
                  style: TextStyle(
                    color: AppColors.textoMuitoFraco,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIcon() {
    return const SizedBox(
      key: ValueKey('loading'),
      width: 82,
      height: 82,
      child: CircularProgressIndicator(
        color: AppColors.destaque,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildCheckIcon() {
    return Container(
      key: const ValueKey('check'),
      width: 82,
      height: 82,
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
        color: AppColors.card,
        size: 46,
      ),
    );
  }

  Widget _buildResumoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.bordaClara,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          _ResumoRow(
            label: 'Startup',
            value: widget.oferta.empresa,
          ),
          const SizedBox(height: 12),
          _ResumoRow(
            label: 'Operação',
            value: _isCompra ? 'Compra' : 'Venda',
          ),
          const SizedBox(height: 12),
          _ResumoRow(
            label: 'Taxa simulada',
            value: 'R\$ ${widget.taxa.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          const Divider(
            color: AppColors.bordaClara,
            height: 1,
          ),
          const SizedBox(height: 12),
          _ResumoRow(
            label: 'Total',
            value: 'R\$ ${widget.totalFinal.toStringAsFixed(2)}',
            destaque: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String label, bool done) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 24,
          height: 24,
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
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.card,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
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
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ResumoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool destaque;

  const _ResumoRow({
    required this.label,
    required this.value,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: destaque ? AppColors.destaque : AppColors.textoPrincipal,
              fontSize: destaque ? 16 : 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}