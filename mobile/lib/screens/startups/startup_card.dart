/* Victória Nobre - 25016398 */

import 'package:flutter/material.dart';

import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/screens/startups/startup_data.dart';

/* Componente de Apresentação de Ativo (Marketplace Item).
   Implementa a visão de card para o catálogo. Utiliza ClipRRect para garantir
   bordas arredondadas em imagens dinâmicas e gradientes lineares para assegurar 
   contraste de texto sobre elementos visuais heterogêneos. */
class StartupCard extends StatelessWidget {
  final StartupData data;
  final VoidCallback onDetailsTap;

  const StartupCard({
    super.key,
    required this.data,
    required this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalTokens = data.totalTokens <= 0 ? data.tokens : data.totalTokens;
    final soldTokens = (totalTokens - data.tokens).clamp(0, totalTokens);
    final progress = totalTokens <= 0 ? 0.0 : soldTokens / totalTokens;
    final progressPercent = (progress * 100).round();
    final capturedValue = soldTokens * data.minBuyPrice;

    return GestureDetector(
      onTap: onDetailsTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.bordaClara, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.38),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: AppColors.destaque.withValues(alpha: 0.04),
              blurRadius: 22,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StartupImageHeader(data: data),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textoPrincipal,
                        height: 1.18,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: _InfoItem(
                            label: 'Tokens',
                            value: data.tokens.toString(),
                            icon: Icons.token_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoItem(
                            label: 'Valor/token',
                            value: 'R\$ ${data.minBuyPrice.toStringAsFixed(2)}',
                            icon: Icons.paid_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _InfoItem(
                            label: 'Mín. de entrada',
                            value: data.investimentoMinimo > 0
                                ? 'R\$ ${data.investimentoMinimo.toStringAsFixed(2)}'
                                : 'Sem mínimo',
                            icon: Icons.trending_up_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _ProgressBlock(
                      progress: progress,
                      progressPercent: progressPercent,
                      capturedValue: capturedValue,
                      goal: data.goal,
                    ),

                    const SizedBox(height: 18),

                    _DetailsButton(onTap: onDetailsTap),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* Cabeçalho Visual com Lazy Loading.
   Gerencia a renderização de imagens remotas com tratamento de erro (Error Builder) 
   e sobreposição de badges informativas que indicam o estado da captação em tempo real. */
class _StartupImageHeader extends StatelessWidget {
  final StartupData data;

  const _StartupImageHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 185,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            data.image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.campo,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textoMuitoFraco,
                  size: 34,
                ),
              );
            },
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.62),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          Positioned(
            left: 16,
            top: 16,
            child: _PillTag(label: data.tag, icon: Icons.auto_awesome_rounded),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.destaque.withValues(alpha: 0.16),
                    border: Border.all(
                      color: AppColors.destaque.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.destaque.withValues(alpha: 0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.destaque,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Rodada aberta para investidores',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textoPrincipal,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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
}

class _PillTag extends StatelessWidget {
  final String label;
  final IconData icon;

  const _PillTag({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.azul.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textoPrincipal, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.campo,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.bordaClara),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.destaque.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.destaque.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: AppColors.destaque, size: 18),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.55),
                    letterSpacing: 0.9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textoPrincipal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* Indicador visual do sucesso da captação em relação à meta financeira estabelecida. */
class _ProgressBlock extends StatelessWidget {
  final double progress;
  final int progressPercent;
  final double capturedValue;
  final double goal;

  const _ProgressBlock({
    required this.progress,
    required this.progressPercent,
    required this.capturedValue,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fundoEscuro.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.bordaClara),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Captação',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$progressPercent%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.destaque,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.campo,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.destaque,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                'Captado',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const Spacer(),
              Text(
                'R\$ ${capturedValue.toStringAsFixed(2)} / R\$ ${goal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* Botão de ação principal para aprofundar le conhecimento sobre a oportunidade. */
class _DetailsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DetailsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.destaqueClaro, AppColors.destaqueEscuro],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.destaque.withValues(alpha: 0.20),
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
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ver detalhes',
                  style: TextStyle(
                    color: AppColors.card,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.card,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
