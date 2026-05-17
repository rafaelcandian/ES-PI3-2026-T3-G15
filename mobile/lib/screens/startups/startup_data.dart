import 'package:cloud_firestore/cloud_firestore.dart';

class StartupData {
  final String id;

  final String title;
  final String subtitle;
  final String tag;

  final double equity;
  final int tokens;
  final double tokenValue;
  final double progress;
  final double goal;

  final String image;
  final String video;

  final String description;
  final String stage;
  final String status;

  final int totalTokens;
  final int investorsCount;

  final String market;
  final double valuation;

  const StartupData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.equity,
    required this.tokens,
    required this.tokenValue,
    required this.progress,
    required this.goal,
    required this.image,
    required this.video,

    required this.description,
    required this.stage,
    required this.status,
    required this.totalTokens,
    required this.investorsCount,
    required this.market,
    required this.valuation,
  });

  factory StartupData.fromMap(
    Map<String, dynamic> data, {
    String id = '',
  }) {
    return StartupData(
      id: id,

      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      tag: data['tag'] ?? '',

      equity: (data['equity'] as num?)?.toDouble() ?? 0.0,
      tokens: (data['tokens'] as num?)?.toInt() ?? 0,

      tokenValue: (data['tokenValue'] as num?)?.toDouble() ?? 0.0,
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
      goal: (data['goal'] as num?)?.toDouble() ?? 0.0,

      image: data['image'] ?? '',
      video: data['video'] ?? '',

      description: data['description'] ?? '',

      stage: data['stage'] ?? data['estagio'] ?? 'Nova',

      status: data['status'] ?? 'open',

      totalTokens:
          (data['totalTokens'] as num?)?.toInt() ?? 0,

      investorsCount:
          (data['investorsCount'] as num?)?.toInt() ?? 0,

      market: data['market'] ?? '',

      valuation:
          (data['valuation'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory StartupData.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return StartupData.fromMap(
      data,
      id: doc.id,
    );
  }
}