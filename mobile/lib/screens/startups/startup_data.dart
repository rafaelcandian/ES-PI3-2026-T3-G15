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
  });

  factory StartupData.fromMap(Map<String, dynamic> data, {String id = ''}) {
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
    );
  }

  factory StartupData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return StartupData(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      tag: data['tag'] ?? '',
      equity: (data['equity'] as num?)?.toDouble() ?? 0.0,
      tokens: (data['tokens'] as num?)?.toInt() ?? 0,
      tokenValue: (data['tokenValue'] as num?)?.toDouble() ?? 0.0,
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
      goal: (data['goal'] as num?)?.toDouble() ?? 0.0,
      image: data['image'] ?? '',
    );
  }
}