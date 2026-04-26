import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mescla_invest/screens/startups/startup_data.dart';

class StartupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<StartupData>> getStartups() {
    return _firestore.collection('startups').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => StartupData.fromFirestore(doc)).toList();
    });
  }

  Future<void> seedStartups() async {
    try {
      final querySnapshot = await _firestore.collection('startups').limit(1).get();
      if (querySnapshot.docs.isEmpty) {
        // Collection is empty, seed initial data
        final List<Map<String, dynamic>> initialStartups = [
          {
            "title": "ShopLink Digital S.A.",
            "subtitle": "Plataforma omnichannel para integração de vendas",
            "tag": "Varejo",
            "equity": 0.10, // Converted from "10%"
            "tokens": 800000, // Converted from "800000"
            "tokenValue": 1.00,
            "progress": 0.65,
            "goal": 800000.00, // Converted from "R$ 800.000"
            "image": "https://images.unsplash.com/photo-1550751827-4bd374c3f58b", // Default image added
          },
          {
            "title": "FinNova Bank Tech S.A.",
            "subtitle": "Banco digital com IA para crédito e investimentos",
            "tag": "Bancário",
            "equity": 0.10, // Converted from "10%"
            "tokens": 2000000, // Converted from "2000000"
            "tokenValue": 1.00,
            "progress": 0.80,
            "goal": 2000000.00, // Converted from "R$ 2.000.000"
            "image": "https://images.unsplash.com/photo-1620616147171-46ad2f0e0c09", // Default image added
          },
          {
            "title": "LogiSmart Solutions S.A.",
            "subtitle": "Logística inteligente com IoT e otimização de rotas",
            "tag": "Logística",
            "equity": 0.10, // Converted from "10%"
            "tokens": 1200000, // Converted from "1200000"
            "tokenValue": 1.00,
            "progress": 0.55,
            "goal": 1200000.00, // Converted from "R$ 1.200.000"
            "image": "https://images.unsplash.com/photo-1563811802958-693081e74f1c", // Default image added
          },
          {
            "title": "AgroVision Tech S.A.",
            "subtitle": "Monitoramento agrícola com drones e sensores",
            "tag": "Agronegócio",
            "equity": 0.10, // Converted from "10%"
            "tokens": 1500000, // Converted from "1500000"
            "tokenValue": 1.00,
            "progress": 0.70,
            "goal": 1500000.00, // Converted from "R$ 1.500.000"
            "image": "https://images.unsplash.com/photo-1543329094-07d23d8c2b7f", // Default image added
          },
          {
            "title": "SmartMarket Connect S.A.",
            "subtitle": "Supermercado inteligente com autoatendimento",
            "tag": "Supermercado",
            "equity": 0.10, // Converted from "10%"
            "tokens": 900000, // Converted from "900000"
            "tokenValue": 1.00,
            "progress": 0.60,
            "goal": 900000.00, // Converted from "R$ 900.000"
            "image": "https://images.unsplash.com/photo-1594918732002-eb82845c48b2", // Default image added
          },
        ];

        for (var startupData in initialStartups) {
          await _firestore.collection('startups').add(startupData);
        }
        print('Startups seeded successfully!');
      } else {
        print('Startups collection already contains data. Skipping seed.');
      }
    } catch (e) {
      print('Error seeding startups: $e');
    }
  }
}
