/* Victória Nobre - 25016398 */
import 'package:flutter/material.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';

/* Card de seção para agrupar conteúdos relacionados com estilo Premium consistente */
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: premiumCardDecoration(radius: radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.72),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}
