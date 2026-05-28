import 'package:cloud_firestore/cloud_firestore.dart';

class StartupData {
  final String id;

  final String title;
  final String subtitle;
  final String tag;

  final double equity;
  final int tokens;
  final double tokenValue;
  final double minBuyPrice;
  final double progress;
  final double goal;
  final double investimentoMinimo;

  final String image;
  final String video;

  final String description;
  final String stage;
  final String status;

  final int totalTokens;
  final int investorsCount;

  final String market;
  final double valuation;

  final List<StartupPartner> partners;

  const StartupData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.equity,
    required this.tokens,
    required this.tokenValue,
    required this.minBuyPrice,
    required this.progress,
    required this.goal,
    required this.investimentoMinimo,
    required this.image,
    required this.video,
    required this.description,
    required this.stage,
    required this.status,
    required this.totalTokens,
    required this.investorsCount,
    required this.market,
    required this.valuation,
    required this.partners,
  });

  factory StartupData.fromMap(Map<String, dynamic> data, {String id = ''}) {
    final tokenValue =
        (data['tokenValue'] as num?)?.toDouble() ??
        (data['valorToken'] as num?)?.toDouble() ??
        1.0;

    final minBuyPrice =
        (data['minBuyPrice'] as num?)?.toDouble() ??
        (data['tokenValue'] as num?)?.toDouble() ??
        (data['valorToken'] as num?)?.toDouble() ??
        1.0;

    final tokens =
        (data['tokens'] as num?)?.toInt() ??
        (data['tokensDisponiveis'] as num?)?.toInt() ??
        (data['quantidadeTokens'] as num?)?.toInt() ??
        (data['availableTokens'] as num?)?.toInt() ??
        (data['quantidade'] as num?)?.toInt() ??
        0;

    return StartupData(
      id: id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      tag: data['tag'] ?? '',
      equity: (data['equity'] as num?)?.toDouble() ?? 0.0,
      tokens: tokens,
      tokenValue: tokenValue,
      minBuyPrice: minBuyPrice,
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
      goal: (data['goal'] as num?)?.toDouble() ?? 0.0,
      investimentoMinimo:
          (data['investimentoMinimo'] as num?)?.toDouble() ?? 0.0,
      image: data['image'] ?? '',
      video: data['video'] ?? '',
      description: data['description'] ?? '',
      stage: data['stage'] ?? data['estagio'] ?? 'Nova',
      status: data['status'] ?? 'open',
      totalTokens: (data['totalTokens'] as num?)?.toInt() ?? 0,
      investorsCount: (data['investorsCount'] as num?)?.toInt() ?? 0,
      market: data['market'] ?? '',
      valuation: (data['valuation'] as num?)?.toDouble() ?? 0.0,
      partners: (data['partners'] as List<dynamic>? ?? [])
          .map((item) {
            if (item is Map<String, dynamic>) {
              return StartupPartner.fromMap(item);
            }

            if (item is Map) {
              return StartupPartner.fromMap(Map<String, dynamic>.from(item));
            }

            return const StartupPartner(name: '', role: '', equityPercent: 0.0);
          })
          .where((partner) => partner.name.trim().isNotEmpty)
          .toList(),
    );
  }

  factory StartupData.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return StartupData.fromMap(data, id: doc.id);
  }
}

class StartupPartner {
  final String name;
  final String role;
  final double equityPercent;

  const StartupPartner({
    required this.name,
    required this.role,
    required this.equityPercent,
  });

  factory StartupPartner.fromMap(Map<String, dynamic> data) {
    return StartupPartner(
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      equityPercent: (data['equityPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
