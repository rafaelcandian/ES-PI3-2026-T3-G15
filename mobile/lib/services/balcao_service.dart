// ignore_for_file: avoid_print
// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/models/order_model.dart';

class BalcaoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }
    return user.uid;
  }

  Stream<List<Map<String, dynamic>>> getOpenOffers(String startupId) {
    return _firestore
        .collection('orders')
        .where('startupId', isEqualTo: startupId)
        .where('status', isEqualTo: OrderStatus.open.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<String?> createPurchaseOffer({
    required String startupId,
    required int quantity,
    required double pricePerToken,
  }) async {
    try {
      _uid;

      final callable = FirebaseFunctions.instance.httpsCallable('createOffer');

      await callable.call({
        'startupId': startupId,
        'type': 'buy',
        'quantity': quantity,
        'pricePerToken': pricePerToken,
      });

      return null;
    } on FirebaseFunctionsException catch (e) {
      return _handleFunctionError(e, fallback: 'Erro ao criar ordem de compra');
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }

  Future<String?> createSellOffer({
    required String startupId,
    required int quantity,
    required double pricePerToken,
  }) async {
    try {
      _uid;

      final callable = FirebaseFunctions.instance.httpsCallable('createOffer');

      await callable.call({
        'startupId': startupId,
        'type': 'sell',
        'quantity': quantity,
        'pricePerToken': pricePerToken,
      });

      return null;
    } on FirebaseFunctionsException catch (e) {
      return _handleFunctionError(e, fallback: 'Erro ao criar ordem de venda');
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }

  Future<String?> comprarDiretoDaStartup({
    required String startupId,
    required int quantity,
    required double pricePerToken,
  }) async {
    try {
      _uid;

      final callable = FirebaseFunctions.instance.httpsCallable('directPurchase');

      await callable.call({
        'startupId': startupId,
        'quantity': quantity,
        'pricePerToken': pricePerToken,
      });

      return null;
    } on FirebaseFunctionsException catch (e) {
      return _handleFunctionError(e, fallback: 'Erro ao realizar compra');
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }

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
        final order = OrderModel.fromFirestore(doc.data(), doc.id);

        if (order.quantity <= 0) continue;

        if (order.type == OrderType.buy) {
          buyOrders = OrderModel.insertBuyOrder(buyOrders, order);
        } else {
          sellOrders = OrderModel.insertSellOrder(sellOrders, order);
        }
      }
    } catch (e) {
      print('Erro ao buscar ordens: $e');
    }

    return {
      OrderType.buy.name: buyOrders,
      OrderType.sell.name: sellOrders,
    };
  }

  String _handleFunctionError(
    FirebaseFunctionsException e, {
    required String fallback,
  }) {
    switch (e.code) {
      case 'failed-precondition':
        return e.message ?? 'Operação não permitida.';
      case 'invalid-argument':
        return e.message ?? 'Dados inválidos.';
      case 'not-found':
        return e.message ?? 'Recurso não encontrado.';
      case 'unauthenticated':
        return 'Usuário não autenticado.';
      default:
        return '$fallback: ${e.message ?? e.code}';
    }
  }
}
