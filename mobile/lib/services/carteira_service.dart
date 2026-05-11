import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/trasacao_model.dart';

class CarteiraService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

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

  // Retorna o documento do usuário em tempo real.
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream() {
    return _userRef.snapshots();
  }

  // Retorna o saldo atual do usuário.
  Future<double> getBalance() async {
    final doc = await _userRef.get();
    final data = doc.data();

    if (data == null) return 0.0;

    return (data['saldo'] as num? ?? 0).toDouble();
  }

  // Retorna o mapa de tokens do usuário.
  Future<Map<String, dynamic>> getTokens() async {
    final doc = await _userRef.get();
    final data = doc.data();

    if (data == null) return {};

    return Map<String, dynamic>.from(data['tokens'] ?? {});
  }

  // Retorna o histórico de transações da carteira em tempo real.
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

  // Adiciona saldo fictício via Pix simulado.
  //
  // Atenção:
  // Este método ainda atualiza direto no Firestore.
  // Depois, para o escopo ficar 100% via Function, o ideal é migrar
  // essa operação para chamar a Function loadWallet.
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

  // Método antigo mantido caso alguma tela já esteja usando.
  Future<String?> addBalance(double valor) async {
    try {
      await addBalancePixSimulado(valor);
      return null;
    } catch (e) {
      return 'Erro: $e';
    }
  }

  // Verifica se o usuário tem saldo suficiente.
  Future<bool> hasSufBalance(double valor) async {
    final saldo = await getBalance();
    return saldo >= valor;
  }

  // Converte os nomes usados no front para os períodos esperados pela Function.
  String _mapPeriodoGrafico(String periodo) {
    switch (periodo) {
      case '1h':
        return '1h';
      case '24h':
        return '24h';
      case '1 sem':
        return '1sem';
      case '1 mês':
        return '1mes';
      case '6 meses':
        return '6meses';
      case '1 ano':
        return '1ano';
      default:
        return '1mes';
    }
  }

  // Busca os valores do gráfico da carteira usando a Function getWalletChart.
  //
  // A Function retorna uma lista de pontos com:
  // {
  //   value: double,
  //   label: string,
  //   createdAt: string
  // }
  //
  // Como o LineChartPainter atual só precisa de List<double>,
  // este método extrai apenas os valores.
  Future<List<double>> getWalletChartValues({
    required String periodo,
  }) async {
    try {
      final callable = _functions.httpsCallable('getWalletChart');

      final result = await callable.call({
        'period': _mapPeriodoGrafico(periodo),
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final points = List<dynamic>.from(data['points'] ?? []);

      final values = points
          .map((point) {
        final pointMap = Map<String, dynamic>.from(point as Map);
        return (pointMap['value'] as num?)?.toDouble() ?? 0.0;
      })
          .where((value) => value > 0)
          .toList();

      return values;
    } catch (e) {
      throw Exception('Erro ao carregar gráfico da carteira: $e');
    }
  }

  // Busca os pontos completos do gráfico.
  //
  // Esse método é opcional, mas já deixo pronto porque depois pode ser útil
  // para exibir labels no gráfico, como "10:00", "11/05", "05/2026" etc.
  Future<List<Map<String, dynamic>>> getWalletChartPoints({
    required String periodo,
  }) async {
    try {
      final callable = _functions.httpsCallable('getWalletChart');

      final result = await callable.call({
        'period': _mapPeriodoGrafico(periodo),
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final points = List<dynamic>.from(data['points'] ?? []);

      return points.map((point) {
        return Map<String, dynamic>.from(point as Map);
      }).toList();
    } catch (e) {
      throw Exception('Erro ao carregar pontos do gráfico da carteira: $e');
    }
  }
}