// ignore_for_file: avoid_print
// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/services/carteira_service.dart';
import 'package:mescla_invest/models/order_model.dart';

/* O balcao_service vai utilizar de uma nova coleção (até então nao existia), chamada orders (termo usado para compra e venda de oferta)
a decisão da criação da coleção orders é porque em um unico documento pode ser representado qualquer tipo de oferta, guardar as ofertas
dentro dos documentos de usuario faria com que quando mostrar as ofertas de venda dos outros usuarios, precisaria ser feito uma busca em
todos os usuarios para montar o balcão. Com uma coleção nova, uma unica consulta traz todas as ofertas abertas de uma startup*/

class BalcaoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CarteiraService _carteira = CarteiraService();

  Future<String?> get _uid async {
  if (_auth.currentUser != null) return _auth.currentUser!.uid;
  final user = await _auth.authStateChanges()
      .firstWhere((u) => u != null, orElse: () => null); // varre a lista procurando itens não nulos, se não achar nenhum returna null
  return user?.uid;
}

  // busca as ofertas abertas de uma startup
  Stream<List<Map<String, dynamic>>> getOpenOffers(String startupId) {
    return _firestore
        .collection('orders')
        .where('startupId', isEqualTo: startupId)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs // snapshot neste caso vai representar o estado atual da coleção no firestore
              .map((doc) => {'id': doc.id, ...doc.data()}) // os "..." indicam que é pra pegar todos os itens dentro do doc
              .toList(), // converte em lista (neste caso converte o map)
        );
  }

  // cria oferta para compra — delega à Cloud Function 'createOffer' para garantir
  // validação de saldo e atomicidade no backend (sem escrita direta no Firestore)
  Future<String?> createPurchaseOffer({
    required String startupId, // required define que o parametro é obrigatorio
    required int quantity,
    required double pricePerToken,
  }) async {
    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('createOffer');
      await callable.call({
        'startupId': startupId,
        'type': 'buy',
        'quantity': quantity,
        'pricePerToken': pricePerToken,
      });
      return null; // aqui finaliza a ação depois de ter criado a ordem
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'failed-precondition':
          return e.message ?? 'Operação não permitida';
        case 'not-found':
          return 'Recurso não encontrado';
        case 'unauthenticated':
          return 'Usuário não autenticado';
        default:
          return 'Erro ao criar ordem: ${e.message}';
      }
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }

  // criar oferta de venda — delega à Cloud Function 'createOffer' para garantir
  // validação de tokens e atomicidade no backend (sem escrita direta no Firestore)
  Future<String?> createSellOffer({
  required String startupId,
  required int quantity,
  required double pricePerToken,
}) async {
  try {
    final callable = FirebaseFunctions.instance
        .httpsCallable('createOffer');
    await callable.call({
      'startupId': startupId,
      'type': 'sell',
      'quantity': quantity,
      'pricePerToken': pricePerToken,
    });
    return null;
  } on FirebaseFunctionsException catch (e) {
    switch (e.code) {
      case 'failed-precondition':
        return e.message ?? 'Operação não permitida';
      case 'not-found':
        return 'Recurso não encontrado';
      case 'unauthenticated':
        return 'Usuário não autenticado';
      default:
        return 'Erro ao criar ordem: ${e.message}';
    }
  } catch (e) {
    return 'Erro inesperado: $e';
  }
}

    // busca todas as ordens abertas de uma startup e retorna duas listas separadas
    Future<Map<String, List<OrderModel>>> getOpenedOrders(
    String startupId,
    ) async {
    List<OrderModel> buyOrders = [];
    List<OrderModel> sellOrders = [];

    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('startupId', isEqualTo: startupId)
          .where('status', isEqualTo: OrderStatus.open.name)
          .orderBy('createdAt', descending: false)
          .get();

      for (final doc in snapshot.docs) {
        final posOrder = OrderModel.fromFirestore(doc.data(), doc.id);

        if (posOrder.type == OrderType.buy) {
          buyOrders = OrderModel.insertBuyOrder(buyOrders, posOrder);
        } else {
          sellOrders = OrderModel.insertSellOrder(sellOrders, posOrder);
        }
      }

    } catch (e) {
      print("Erro ao buscar ordens: $e");
    }

    return {
      OrderType.buy.name: buyOrders,
      OrderType.sell.name: sellOrders,
    };
  }
}
