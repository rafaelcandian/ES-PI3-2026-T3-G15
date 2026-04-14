import 'package:flutter/material.dart';
import 'package:mescla_invest/screens/startups/startup_data.dart';

class StartupCard extends StatelessWidget {
  final StartupData data;

  const StartupCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(Icons.business, size: 40, color: Colors.orangeAccent),
        title: Text(data.title),
        subtitle: Text(data.subtitle),
        trailing: Text(data.equity),
      ),
    );
  }
}