import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CarteiraService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth
      .currentUser! // O "!" garante que vai ser retornado um valor não nulo
      .uid;

  // 1. Retorna o documento usuario
  Stream<DocumentSnapshot> getUserStream() {
    return _firestore.collection('usuarios').doc(_uid).snapshots();
  }

  // 2. Pega o valor do 'saldo'
  Future<double> getBalance() async {
    final doc = await _firestore.collection('usuarios').doc(_uid).get();
    return (doc.data() as Map<String, dynamic>)['saldo'] ?? 0.0; // se for nulo vai retornar 0
  }

  Future<Map<String, dynamic>> getTokens() async {
    final doc = await _firestore.collection('usuarios').doc(_uid).get();
    return (doc.data() as Map<String, dynamic>)['tokens'] ?? {}; // se for nulo retorna uma lista vazia
  }
}
