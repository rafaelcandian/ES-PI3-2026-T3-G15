/* Victória Nobre - 25016398 */
// Autor: Arthur Valerio De Santi
// RA: 25006924

import 'package:cloud_firestore/cloud_firestore.dart';

/* Representação de uma ordem de compra ou venda no sistema de balcão */
enum OrderType { buy, sell }

/* Estados possíveis de uma ordem no livro de ofertas */
enum OrderStatus { open, filled, cancelled }

class OrderModel {
  final String id;
  final String userId;
  final String startupId;
  final OrderType type;
  final int quantity;
  final double pricePerToken;
  final double totalPrice;
  final OrderStatus status;
  final DateTime createdAt;

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

  /* Mapeia dados do Firestore para a model, garantindo conversão segura de tipos numéricos e datas */
  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    final createdAtRaw = data['createdAt'];

    return OrderModel(
      id: id,
      userId: (data['userId'] ?? '').toString(),
      startupId: (data['startupId'] ?? '').toString(),
      type: OrderType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => OrderType.buy,
      ),
      quantity:
          (data['quantity'] as num?)?.toInt() ??
          (data['quantidade'] as num?)?.toInt() ??
          (data['tokens'] as num?)?.toInt() ??
          0,
      pricePerToken: (data['pricePerToken'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.open,
      ),
      createdAt: createdAtRaw is Timestamp
          ? createdAtRaw.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

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

  static Map<int, OrderModel> _invertSignals(List<OrderModel> list) {
    final map = <int, OrderModel>{};

    for (int i = 0; i < list.length; i++) {
      map[i] = OrderModel(
        id: list[i].id,
        userId: list[i].userId,
        startupId: list[i].startupId,
        type: list[i].type,
        quantity: list[i].quantity,
        pricePerToken: -list[i].pricePerToken,
        totalPrice: -list[i].totalPrice,
        status: list[i].status,
        createdAt: list[i].createdAt,
      );
    }

    return map;
  }

  static List<OrderModel> _restoreSignals(Map<int, OrderModel> map) {
    return map.values
        .map(
          (order) => OrderModel(
            id: order.id,
            userId: order.userId,
            startupId: order.startupId,
            type: order.type,
            quantity: order.quantity,
            pricePerToken: -order.pricePerToken,
            totalPrice: -order.totalPrice,
            status: order.status,
            createdAt: order.createdAt,
          ),
        )
        .toList();
  }

  static void _insertMap(Map<int, OrderModel> map, OrderModel newOrder) {
    int pos = 0;
    final list = map.values.toList();

    while (pos < list.length &&
        newOrder.pricePerToken > list[pos].pricePerToken) {
      pos++;
    }

    for (int i = map.length; i > pos; i--) {
      map[i] = map[i - 1]!;
    }

    map[pos] = newOrder;
  }

  static List<OrderModel> insertSellOrder(
    List<OrderModel> list,
    OrderModel newOrder,
  ) {
    final map = <int, OrderModel>{};

    for (int i = 0; i < list.length; i++) {
      map[i] = list[i];
    }

    _insertMap(map, newOrder);
    return map.values.toList();
  }

  static List<OrderModel> insertBuyOrder(
    List<OrderModel> list,
    OrderModel newOrder,
  ) {
    final invMap = _invertSignals(list);

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
    return _restoreSignals(invMap);
  }
}
