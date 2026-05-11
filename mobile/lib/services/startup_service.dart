import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mescla_invest/screens/startups/startup_data.dart';

class StartupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<StartupData>> getStartups() {
    return _firestore.collection('main_screens').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => StartupData.fromFirestore(doc)).toList();
    });
  }

  Future<void> seedStartups() async {
    try {
      final querySnapshot = await _firestore.collection('main_screens').limit(1).get();
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
            "image": "https://firebasestorage.googleapis.com/v0/b/es-pi3-2026-t3-g15.firebasestorage.app/o/logos%2FShopLink.jpeg?alt=media&token=bec0ea63-f925-45c7-aad8-07d1ab04ee0f",
            "video": "https://firebasestorage.googleapis.com/v0/b/es-pi3-2026-t3-g15.firebasestorage.app/o/videos%2FShopLink.mp4?alt=media&token=288d33a6-8732-493f-8efa-0ce27d5b832d"
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
            "image": "https://firebasestorage.googleapis.com/v0/b/es-pi3-2026-t3-g15.firebasestorage.app/o/logos%2FFinNova.jpeg?alt=media&token=b2c452fd-d6f4-41bd-a33d-20ed49f23d03",
            "video": "https://firebasestorage.googleapis.com/v0/b/es-pi3-2026-t3-g15.firebasestorage.app/o/videos%2FFinNova.mp4?alt=media&token=5ffba202-3f1b-43b7-b522-8bbb63ea9a5b"
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
            "image": "https://firebasestorage.googleapis.com/v0/b/es-pi3-2026-t3-g15.firebasestorage.app/o/logos%2FLogiSmart.jpeg?alt=media&token=4b6cc6dd-bcc6-4d0c-82ab-28a202b06fc6",
            "video": "https://firebasestorage.googleapis.com/v0/b/es-pi3-2026-t3-g15.firebasestorage.app/o/videos%2FLogiSmart.mp4?alt=media&token=ee50bb54-f140-4100-9c2c-e116b8b4b272"
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
            "image": "https://firebasestorage.googleapis.com/v0/b/es-pi3-2026-t3-g15.firebasestorage.app/o/logos%2FAgroVision.jpeg?alt=media&token=14cee889-78bc-474d-a103-20a32a3e2808",
            "video": "https://firebasestorage.googleapis.com/v0/b/es-pi3-2026-t3-g15.firebasestorage.app/o/videos%2FAgroVision.mp4?alt=media&token=d3bdc98d-4f47-4dd5-8d08-cbcd9b534150"
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
            "image": "https://firebasestorage.googleapis.com/v0/b/es-pi3-2026-t3-g15.firebasestorage.app/o/logos%2FSmartMarket.jpeg?alt=media&token=a97e5c96-2c5b-4903-a617-31c5a5b8af4a",
            "video": "https://firebasestorage.googleapis.com/v0/b/es-pi3-2026-t3-g15.firebasestorage.app/o/videos%2FSmartMarket.mp4?alt=media&token=69ba4f42-d339-4eb7-9b53-84bbe69194de"
          },
        ];

        for (var startupData in initialStartups) {
          await _firestore.collection('main_screens').add(startupData);
        }
        print('Startups seeded successfully!');
      } else {
        print('Startups collection already contains data. Skipping seed.');
      }
    } catch (e) {
      print('Error seeding main_screens: $e');
    }
  }
}
