import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mescla_invest/screens/startups/startup_data.dart';

class StartupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<StartupData>> getStartups() {
    return _firestore.collection('startups').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => StartupData.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> seedStartups() async {
    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('seedStartupCatalog');

      final result = await callable.call();

      print(result.data['message']);
    } on FirebaseFunctionsException catch (e) {
      print('Erro ao executar seed: ${e.message}');
    }
  }
}