import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/services/carteira_service.dart';

/* O balcao_service vai utilizar de uma nova coleção (até então nao existia), chamada orders (termo usado para compra e venda de oferta)
a decisão da criação da coleção orders é porque em um unico documento pode ser representado qualquer tipo de oferta, guardar as ofertas
dentro dos documentos de usuario faria com que quando mostrar as ofertas de venda dos outros usuarios, precisaria ser feito uma busca em
todos os usuarios para montar o balcão. Com uma coleção nova, uma unica consulta traz todas as ofertas abertas de uma startup*/

class BalcaoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CarteiraService _carteira = CarteiraService();

  String get _uid => _auth.currentUser!.uid;

  // busca as ofertas abertas de uma startup
  Stream<List<Map<String, dynamic>>> getOpenOffers(String startupId) {
    return _firestore
        .collection('orders')
        .where('startupId', isEqualTo: startupId)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  // cria oferta para compra
  Future<String?> createPurchaseOffer({
    required String startupId, // required define que o parametro é obrigatorio
    required int quantity,
    required double pricePerToken,
  }) async {
    if (quantity <= 0) return "quantidade invalida";
    if (pricePerToken <= 0) return "Preço invalido";

    final totalPrice = quantity * pricePerToken;

    // valida o saldo
    final haveBalance = await _carteira.hasSufBalance(totalPrice);
    if (!haveBalance) return "saldo insuficiente";

    try {
      await _firestore.collection('orders').add({
        'userId': _uid,
        'startupId': startupId,
        'type': 'buy',
        'quantity': quantity,
        'pricePerToken': pricePerToken,
        'totalPrice': totalPrice,
        'status': 'open',
        'createdAt': Timestamp.now(),
      });
      return null;
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
    if (quantity <= 0) return "quantidade invalida";
    if (pricePerToken <= 0) return "preço invalido";

    final tokens = await _carteira.getTokens();
    final tokensStartup = tokens[startupId] ?? 0;
    if (tokensStartup < quantity) return "tokens insuficientes";

    try {
      await _firestore.collection('orders').add({
        'userId': _uid,
        'startupId': startupId,
        'type': 'buy',
        'quantity': quantity,
        'pricePerToken': pricePerToken,
        'totalPrice': (pricePerToken * quantity),
        'status': 'open',
        'createdAt': Timestamp.now(),
      });
      return null;
    } catch (e) {
      return "Erro: $e";
    }
  }
}
