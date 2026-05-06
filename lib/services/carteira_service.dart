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

  // 2. Retorna o saldo do usuario
  Future<double> getBalance() async {
    final doc = await _firestore.collection('usuarios').doc(_uid).get();
    return (doc.data() as Map<String, dynamic>)['saldo'] ??
        0.0; // se for nulo vai retornar 0
  }

  // 3. Retorna os tokens do usuario
  Future<Map<String, dynamic>> getTokens() async {
    final doc = await _firestore.collection('usuarios').doc(_uid).get();
    return (doc.data() as Map<String, dynamic>)['tokens'] ??
        {}; // se for nulo retorna uma lista vazia
  }

  // 4. Metodo para adicionar saldo ficticio
  Future<String?> addBalance(double valor) async {
    if (valor <= 0) return "Valor invalido";
    try {
      await _firestore.collection('usuarios').doc(_uid).update({
        "saldo": FieldValue.increment(valor),
      });
      return null;
    } catch (e) {
      return "Erro: $e";
    }
  }
}