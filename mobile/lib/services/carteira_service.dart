import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/trasacao_model.dart';



class CarteiraService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userRef {
    return _firestore.collection('usuarios').doc(_uid);
  }

  CollectionReference<Map<String, dynamic>> get _transacoesRef {
    return _userRef.collection('transacoesCarteira');
  }

  // Retorna o documento do usuário em tempo real
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream() {
    return _userRef.snapshots();
  }

  // Retorna o saldo do usuário
  Future<double> getBalance() async {
    final doc = await _userRef.get();
    final data = doc.data();

    if (data == null) return 0.0;

    return (data['saldo'] as num? ?? 0).toDouble();
  }

  // Retorna os tokens do usuário
  Future<Map<String, dynamic>> getTokens() async {
    final doc = await _userRef.get();
    final data = doc.data();

    if (data == null) return {};

    return Map<String, dynamic>.from(data['tokens'] ?? {});
  }

  // Retorna o histórico de transações da carteira
  Stream<List<WalletTransactionModel>> getTransacoesStream() {
    return _transacoesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return WalletTransactionModel.fromFirestore(
          doc.data(),
          doc.id,
        );
      }).toList();
    });
  }

  // Adiciona saldo fictício via Pix simulado
  Future<WalletTransactionModel> addBalancePixSimulado(double valor) async {
    if (valor <= 0) {
      throw Exception('Valor inválido.');
    }

    final transacaoDoc = _transacoesRef.doc();

    final transacao = WalletTransactionModel(
      id: transacaoDoc.id,
      userId: _uid,
      type: WalletTransactionType.deposit,
      status: WalletTransactionStatus.completed,
      amount: valor,
      description: 'Depósito via Pix simulado',
      method: 'pix_simulado',
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();

    batch.update(_userRef, {
      'saldo': FieldValue.increment(valor),
    });

    batch.set(transacaoDoc, transacao.toMap());

    await batch.commit();

    return transacao;
  }

  // Método antigo mantido, caso alguma tela já esteja usando
  Future<String?> addBalance(double valor) async {
    try {
      await addBalancePixSimulado(valor);
      return null;
    } catch (e) {
      return 'Erro: $e';
    }
  }

  // Verifica se o usuário tem saldo suficiente
  Future<bool> hasSufBalance(double valor) async {
    final saldo = await getBalance();
    return saldo >= valor;
  }
}