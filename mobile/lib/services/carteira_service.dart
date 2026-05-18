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
  // Este método chama a Cloud Function loadWallet para
  // incrementar o saldo do usuário de forma segura pelo backend.
  Future<WalletTransactionModel> addBalancePixSimulado(double valor) async {
    try {
      final callable = _functions.httpsCallable('loadWallet');
      await callable.call({'valor': valor});

      return WalletTransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _uid,
        type: WalletTransactionType.deposit,
        status: WalletTransactionStatus.completed,
        amount: valor,
        description: 'Depósito via Pix simulado',
        method: 'pix_simulado',
        createdAt: DateTime.now(),
      );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'invalid-argument') {
        throw Exception('Valor inválido.');
      } else if (e.code == 'not-found') {
        throw Exception('Usuário não encontrado.');
      } else if (e.code == 'unauthenticated') {
        throw Exception('Usuário não autenticado.');
      } else {
        throw Exception(e.message ?? 'Erro ao adicionar fundos.');
      }
    }
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

  // Compra tokens diretamente de uma startup.
  //
  // Esta operação é feita dentro de uma transaction do Firestore para garantir
  // que saldo, tokens do usuário e disponibilidade da startup sejam atualizados juntos.
  Future<void> comprarTokensStartup({
    required String startupId,
    required String startupNome,
    required String simbolo,
    required int quantidade,
    required double precoUnitario,
    required double taxa,
    required double totalFinal,
  }) async {
    if (startupId.trim().isEmpty) {
      throw Exception('Startup inválida para compra.');
    }

    if (quantidade <= 0) {
      throw Exception('Quantidade inválida de tokens.');
    }

    if (precoUnitario <= 0 || totalFinal <= 0) {
      throw Exception('Valor da compra inválido.');
    }

    final uid = _uid;
    final userRef = _firestore.collection('usuarios').doc(uid);
    final startupRef = _firestore.collection('startups').doc(startupId);
    final transacaoRef = userRef.collection('transacoesCarteira').doc();
    final ativoRef = userRef.collection('ativos').doc(startupId);

    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final startupSnapshot = await transaction.get(startupRef);

      if (!userSnapshot.exists) {
        throw Exception('Usuário não encontrado.');
      }

      if (!startupSnapshot.exists) {
        throw Exception('Startup não encontrada.');
      }

      final userData = userSnapshot.data() ?? <String, dynamic>{};
      final startupData = startupSnapshot.data() ?? <String, dynamic>{};

      final saldoAtual = (userData['saldo'] as num? ?? 0).toDouble();
      final tokensDisponiveis = (startupData['tokens'] as num? ?? 0).toInt();

      if (saldoAtual < totalFinal) {
        throw Exception(
          'Saldo insuficiente. Saldo atual: R\$ ${saldoAtual.toStringAsFixed(2)}.',
        );
      }

      if (tokensDisponiveis < quantidade) {
        throw Exception(
          'Tokens insuficientes. Disponível: $tokensDisponiveis tokens.',
        );
      }

      transaction.update(userRef, {
        'saldo': FieldValue.increment(-totalFinal),
        'tokens.$startupId': FieldValue.increment(quantidade),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(startupRef, {
        'tokens': FieldValue.increment(-quantidade),
        'investorsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(
        ativoRef,
        {
          'startupId': startupId,
          'startupNome': startupNome,
          'simbolo': simbolo,
          'quantidadeTokens': FieldValue.increment(quantidade),
          'precoMedioReferencia': precoUnitario,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(transacaoRef, {
        'type': 'purchase',
        'status': 'completed',
        'startupId': startupId,
        'startupNome': startupNome,
        'simbolo': simbolo,
        'quantity': quantidade,
        'pricePerToken': precoUnitario,
        'taxa': taxa,
        'totalPrice': totalFinal,
        'amount': -totalFinal,
        'description': 'Compra de $quantidade tokens de $startupNome',
        'method': 'startup_investment',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
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