// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
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

  // cria oferta para compra
  Future<String?> createPurchaseOffer({
    required String startupId, // required define que o parametro é obrigatorio
    required int quantity,
    required double pricePerToken,
  }) async {
    if (quantity <= 0) return "quantidade invalida";
    if (pricePerToken <= 0) return "preço invalido";

    final uid = await _uid;
    if (uid == null) return "usuário não está logado";

    final totalPrice = (quantity * pricePerToken);

    // valida o saldo
    final haveBalance = await _carteira.hasSufBalance(totalPrice);
    if (!haveBalance) return "saldo insuficiente";

    try {
      await _firestore.collection('orders').add({
        'userId': uid,
        'startupId': startupId,
        'type': OrderType.buy.name,
        'quantity': quantity,
        'pricePerToken': pricePerToken,
        'totalPrice': totalPrice,
        'status': 'open',
        'createdAt': Timestamp.now(),
      });
      return null; // aqui finaliza a ação depois de ter criado a ordem
    } catch (e) {
      return "Erro: $e";
    }
  }

  // criar oferta de venda
  Future<String?> createSellOffer({
  required String startupId,
  required int quantity,
  required double pricePerToken,
}) async {
  final uid = await _uid;

  if (uid == null) return "Usuário não está logado";

  final tokens = await _carteira.getTokens();

  final tokensStartup = tokens[startupId] ?? 0; // caso o tokens[startupId] for null, retorna 0

  if (tokensStartup < quantity) return "tokens insuficientes";

  try {
    await _firestore.collection('orders').add({
      'userId': uid,
      'startupId': startupId,
      'type': OrderType.sell.name, // pega direto do enum no models/order_models
      'quantity': quantity,
      'pricePerToken': pricePerToken,
      'totalPrice': (pricePerToken * quantity),
      'status': OrderStatus.open.name, // pega direto do enum no models/order_models
      'createdAt': Timestamp.now(),
    });
    return null;
  } catch (e) {
    return "Erro: $e";
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
