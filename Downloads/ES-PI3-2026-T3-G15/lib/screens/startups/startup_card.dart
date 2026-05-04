import 'package:flutter/material.dart';
import 'package:mescla_invest/screens/startups/startup_data.dart';

class StartupCard extends StatelessWidget {
  final StartupData data;

  const StartupCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101731),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(data.image, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF1B2348),
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    );
                  }),
                  Container(color: Colors.black.withValues(alpha: 0.25)),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E3B7C),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(data.tag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF050A1D).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${data.equity} Equity', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFFD57E))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                Text(data.subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF9CADDD), height: 1.5)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _InfoItem(label: 'Tokens disponíveis', value: data.tokens.toString())),
                    Expanded(child: _InfoItem(label: 'Valor do token', value: data.tokenValue.toString())),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Captação: ${(data.progress * 100).round()}%', style: const TextStyle(fontSize: 12, color: Color(0xFF7D91C2), fontWeight: FontWeight.w600)),
                    Text(data.goal.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF9CADDD), fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: data.progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF1B2348),
                    color: const Color(0xFFFFC53D),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC53D),
                          foregroundColor: const Color(0xFF0F1749),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: const Text('Ver detalhes →', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
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

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: Color(0xFF5F7BC6), letterSpacing: 0.6, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}