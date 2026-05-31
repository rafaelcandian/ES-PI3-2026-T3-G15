/* Victória Nobre - 25016398 */
/* Guilherme Henrique Moreira - 25006702 */
// Autor: Arthur Valerio De Santi
// RA: 25006924

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/trasacao_model.dart';

/* Gerencia o saldo do usuário, transações da carteira e integração com gráficos financeiros */
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

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream() {
    return _userRef.snapshots();
  }

  // LEITURA DO FIRESTORE (Saldo):
  // Faz uma leitura única (get) no documento do usuário logado para obter seu saldo atual.
  // Este saldo é frequentemente usado para validar se o usuário tem poder de compra suficiente.
  Future<double> getBalance() async {
    final doc = await _userRef.get();
    final data = doc.data();

    if (data == null) return 0.0;

    return (data['saldo'] as num? ?? 0).toDouble();
  }

  // LEITURA DO FIRESTORE (Tokens):
  // Busca a carteira de ativos do usuário (campo 'tokens' no documento).
  // Retorna um mapa onde a chave é o startupId e o valor é a quantidade possuída.
  Future<Map<String, dynamic>> getTokens() async {
    final doc = await _userRef.get();
    final data = doc.data();

    if (data == null) return {};

    return Map<String, dynamic>.from(data['tokens'] ?? {});
  }

  Stream<List<WalletTransactionModel>> getTransacoesStream() {
    return _transacoesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return WalletTransactionModel.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

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
        description: 'Depósito via Pix',
        method: 'pix',
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

  Future<String?> addBalance(double valor) async {
    try {
      await addBalancePixSimulado(valor);
      return null;
    } catch (e) {
      return 'Erro: $e';
    }
  }

  // CÁLCULO DE VALIDAÇÃO:
  // Compara o saldo obtido do Firestore com o valor necessário para a operação.
  // Retorna um booleano (true/false) determinando se a ação pode prosseguir no frontend.
  Future<bool> hasSufBalance(double valor) async {
    final saldo = await getBalance();
    return saldo >= valor;
  }

  /* Realiza a compra de tokens no mercado primário (direto da startup) usando Transação Atômica.
     A técnica de 'Multi-document Transaction' do Firestore é aplicada para garantir as 4 propriedades ACID:
     1. Atomicidade: Todas as atualizações (usuário, startup, ativos, histórico) ocorrem ou nenhuma ocorre.
     2. Consistência: Valida saldo e estoque antes de permitir qualquer escrita no banco.
     3. Isolamento: Impede que duas compras concorrentes usem o mesmo saldo ou lote de tokens simultaneamente.
     4. Durabilidade: Uma vez confirmada pela rede Firebase, a transação é persistente. */
  Future<void> comprarTokensStartup({
    required String startupId,
    required String startupNome,
    required String simbolo,
    required int quantidade,
    required double precoUnitario,
    required double taxa,
    required double totalFinal,
  }) async {
    // ... validações iniciais omitidas para brevidade ...

    final uid = _uid;
    final userRef = _firestore.collection('usuarios').doc(uid);
    final startupRef = _firestore.collection('startups').doc(startupId);
    final transacaoRef = userRef.collection('transacoesCarteira').doc();
    final ativoRef = userRef.collection('ativos').doc(startupId);

    /* O uso de runTransaction garante que o saldo só seja descontado se os tokens estiverem disponíveis, em uma única operação atômica */
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

      /* Validação Crítica Pre-flight: Proteção contra saldo negativo e 'Double Spending'. 
         O snapshot é lido dentro do contexto da transação para garantir dados em tempo real. */
      if (saldoAtual < totalFinal) {
        throw Exception(
          'Saldo insuficiente. Saldo atual: R\$ ${saldoAtual.toStringAsFixed(2)}.',
        );
      }

      /* Validação crítica de disponibilidade de tokens no lote da startup */
      if (tokensDisponiveis < quantidade) {
        throw Exception(
          'Tokens insuficientes. Disponível: $tokensDisponiveis tokens.',
        );
      }

      /* Orquestração da escrita atômica em múltiplos nós do grafo do banco de dados. */
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

      transaction.set(ativoRef, {
        'startupId': startupId,
        'startupNome': startupNome,
        'simbolo': simbolo,
        'quantidadeTokens': FieldValue.increment(quantidade),
        'precoMedioReferencia': precoUnitario,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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

  Future<List<double>> getWalletChartValues({required String periodo}) async {
    try {
      final points = await getWalletChartPoints(periodo: periodo);

      return points
          .map((point) {
            return (point['value'] as num?)?.toDouble() ?? 0.0;
          })
          .where((value) {
            return value > 0;
          })
          .toList();
    } catch (e) {
      print('Erro ao carregar gráfico da carteira: $e');
      return [];
    }
  }

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
      print('Erro ao carregar pontos do gráfico da carteira: $e');
      return [];
    }
  }
}
