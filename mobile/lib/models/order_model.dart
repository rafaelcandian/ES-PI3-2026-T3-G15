/* Victória Nobre - 25016398 */
/* Guilherme Henrique Moreira - 25006702 */
// Autor: Arthur Valerio De Santi
// RA: 25006924

import 'package:cloud_firestore/cloud_firestore.dart';

/* Representa o tipo da ordem no balcão */
enum OrderType { buy, sell }

/* Representa o status atual da ordem */
enum OrderStatus { open, filled, cancelled }

/* Classe responsável por representar uma ordem de compra ou venda */
class OrderModel {
  // ID da ordem no Firestore
  final String id;

  // ID do usuário que criou a ordem
  final String userId;

  // ID da startup relacionada à ordem
  final String startupId;

  // Tipo da ordem: compra ou venda
  final OrderType type;

  // Quantidade de tokens da ordem
  final int quantity;

  // Preço de cada token
  final double pricePerToken;

  // Valor total da ordem
  final double totalPrice;

  // Status da ordem
  final OrderStatus status;

  // Data de criação da ordem
  final DateTime createdAt;

  /* Construtor da classe */
  const OrderModel({
    required this.id,
    required this.userId,
    required this.startupId,
    required this.type,
    required this.quantity,
    required this.pricePerToken,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  /* Converte os dados vindos do Firestore para um objeto OrderModel */
  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    final createdAtRaw = data['createdAt'];

    return OrderModel(
      id: id,
      userId: (data['userId'] ?? '').toString(),
      startupId: (data['startupId'] ?? '').toString(),

      // Converte o texto salvo no banco para o enum OrderType
      type: OrderType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => OrderType.buy,
      ),

      // Busca a quantidade em diferentes campos possíveis do banco
      quantity:
          (data['quantity'] as num?)?.toInt() ??
          (data['quantidade'] as num?)?.toInt() ??
          (data['tokens'] as num?)?.toInt() ??
          0,

      pricePerToken: (data['pricePerToken'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,

      // Converte o texto salvo no banco para o enum OrderStatus
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.open,
      ),

      // Converte Timestamp do Firestore para DateTime do Dart
      createdAt: createdAtRaw is Timestamp
          ? createdAtRaw.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /* Converte o objeto OrderModel para Map, para salvar no Firestore */
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startupId': startupId,
      'type': type.name,
      'quantity': quantity,
      'pricePerToken': pricePerToken,
      'totalPrice': totalPrice,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /* Inverte os sinais dos preços para facilitar a ordenação das ordens de compra */
  static Map<int, OrderModel> _invertSignals(List<OrderModel> list) {
    final map = <int, OrderModel>{};

    for (int i = 0; i < list.length; i++) {
      map[i] = OrderModel(
        id: list[i].id,
        userId: list[i].userId,
        startupId: list[i].startupId,
        type: list[i].type,
        quantity: list[i].quantity,

        // O valor negativo ajuda a reutilizar a mesma lógica de ordenação
        pricePerToken: -list[i].pricePerToken,
        totalPrice: -list[i].totalPrice,
        status: list[i].status,
        createdAt: list[i].createdAt,
      );
    }

    return map;
  }

  /* Restaura os sinais dos preços após a ordenação */
  static List<OrderModel> _restoreSignals(Map<int, OrderModel> map) {
    return map.values
        .map(
          (order) => OrderModel(
            id: order.id,
            userId: order.userId,
            startupId: order.startupId,
            type: order.type,
            quantity: order.quantity,

            // Volta os valores para positivo
            pricePerToken: -order.pricePerToken,
            totalPrice: -order.totalPrice,
            status: order.status,
            createdAt: order.createdAt,
          ),
        )
        .toList();
  }

  /* Insere uma nova ordem no mapa mantendo a ordenação pelo preço */
  static void _insertMap(Map<int, OrderModel> map, OrderModel newOrder) {
    int pos = 0;
    final list = map.values.toList();

    // Procura a posição correta para inserir a nova ordem
    while (pos < list.length &&
        newOrder.pricePerToken > list[pos].pricePerToken) {
      pos++;
    }

    // Move os itens para abrir espaço na posição correta
    for (int i = map.length; i > pos; i--) {
      map[i] = map[i - 1]!;
    }

    // Insere a nova ordem na posição encontrada
    map[pos] = newOrder;
  }

  /* Insere uma ordem de venda mantendo a lista ordenada */
  static List<OrderModel> insertSellOrder(
    List<OrderModel> list,
    OrderModel newOrder,
  ) {
    final map = <int, OrderModel>{};

    // Converte a lista em mapa para facilitar a inserção por posição
    for (int i = 0; i < list.length; i++) {
      map[i] = list[i];
    }

    _insertMap(map, newOrder);
    return map.values.toList();
  }

  /* Insere uma ordem de compra mantendo a lista ordenada */
  static List<OrderModel> insertBuyOrder(
    List<OrderModel> list,
    OrderModel newOrder,
  ) {
    // Inverte os sinais para reaproveitar a lógica de ordenação
    final invMap = _invertSignals(list);

    // Cria a nova ordem também com os valores invertidos
    final invertedOrder = OrderModel(
      id: newOrder.id,
      userId: newOrder.userId,
      startupId: newOrder.startupId,
      type: newOrder.type,
      quantity: newOrder.quantity,
      pricePerToken: -newOrder.pricePerToken,
      totalPrice: -newOrder.totalPrice,
      status: newOrder.status,
      createdAt: newOrder.createdAt,
    );

    _insertMap(invMap, invertedOrder);

    // Restaura os sinais antes de devolver a lista final
    return _restoreSignals(invMap);
  }
}