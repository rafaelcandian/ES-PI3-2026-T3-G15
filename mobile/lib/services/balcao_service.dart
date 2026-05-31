/* Victória Nobre - 25016398 */
// Autor: Arthur Valerio De Santi
// RA: 25006924

// ignore_for_file: avoid_print
// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/models/order_model.dart';

/* Gerencia operações do balcão de negociações P2P via Cloud Functions para garantir atomicidade */
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

  // MÉTODO: getOpenOffers
  // Recupera em tempo real (Stream) todas as ofertas abertas no balcão para uma startup específica.
  // Utilizado para popular o order book (livro de ofertas) na tela de negociações.
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

  /* Cria uma oferta de compra no balcão. Usa Cloud Functions para validar saldo e bloquear o valor em 'garantia' no backend */
  // MÉTODO: createPurchaseOffer
  // Lança uma nova ordem de compra no mercado secundário (balcão).
  // A validação de saldo e bloqueio de fundos ocorre de forma segura no backend.
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
      /* Tratamento de erros específicos retornados pelas regras de negócio do servidor */
      return _handleFunctionError(e, fallback: 'Erro ao criar ordem de compra');
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }

  // MÉTODO: createSellOffer
  // Lança uma nova ordem de venda no mercado secundário.
  // O backend garantirá que os tokens fiquem bloqueados para evitar gastos duplos (double spending).
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

  // MÉTODO: comprarDiretoDaStartup
  // Executa uma compra no mercado primário (direto com a startup).
  // Invoca a Cloud Function 'directPurchase', que lida com a transação atômica.
  Future<String?> comprarDiretoDaStartup({
    required String startupId,
    required int quantity,
    required double pricePerToken,
  }) async {
    try {
      _uid;

      final callable = FirebaseFunctions.instance.httpsCallable(
        'directPurchase',
      );

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

  // MÉTODO: comprarOfertaVendaExistente
  // Executa a contraparte de uma oferta de venda que já está no balcão (Mercado Secundário).
  // Chama a Cloud Function 'executeSellOffer' para realizar a troca de titularidade e valores.
  Future<String?> comprarOfertaVendaExistente({
    required String orderId,
    required int quantity,
    required double totalFinal,
    required double taxa,
  }) async {
    try {
      _uid;

      if (orderId.trim().isEmpty) {
        return 'Oferta inválida.';
      }

      if (quantity <= 0) {
        return 'Quantidade inválida.';
      }

      final callable = FirebaseFunctions.instance.httpsCallable(
        'executeSellOffer',
      );

      await callable.call({
        'orderId': orderId,
        'quantity': quantity,
      });

      return null;
    } on FirebaseFunctionsException catch (e) {
      return _handleFunctionError(
        e,
        fallback: 'Erro ao comprar oferta do balcão',
      );
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }

  // MÉTODO: cancelarOferta
  // Permite que o usuário cancele uma oferta aberta que ele mesmo criou no balcão.
  // Invoca a Cloud Function 'cancelOffer', que libera o saldo ou tokens retidos.
  Future<String?> cancelarOferta({
    required String orderId,
  }) async {
    try {
      _uid;

      final callable = FirebaseFunctions.instance.httpsCallable('cancelOffer');

      await callable.call({
        'orderId': orderId,
      });

      return null;
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'permission-denied':
          return 'Você não tem permissão para cancelar esta oferta';
        case 'failed-precondition':
          return 'Esta oferta não pode ser cancelada';
        case 'not-found':
          return 'Oferta não encontrada';
        default:
          return 'Erro ao cancelar oferta: ${e.message}';
      }
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

    return {OrderType.buy.name: buyOrders, OrderType.sell.name: sellOrders};
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
