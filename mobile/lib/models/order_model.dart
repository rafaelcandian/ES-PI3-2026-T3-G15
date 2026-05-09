import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderType { buy, sell }

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

  OrderModel({
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

  /*
    o factory é um construtor que é utilizado para criar instancias de classes que não nescessariamente
    criam uma nova instância da propria classem, permite retornar instancias de subclasses, realizar logicas
    antes da incialização e permitem o uso de return 
  */

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    return OrderModel(
      id: id,
      userId: data['userId'] ?? '', // se for valor null vai vir uma string vazia ao inves de null
      startupId: data['startupId'] ?? '',
      type: OrderType.values.firstWhere(
        (e) => e.name == data['type'], //verifica se o nome do enum é igual ao type da data se não for ele vai definir como 'buy'
        orElse: () => OrderType.buy,
      ),
      quantity: data['quantity'] ?? 0,
      pricePerToken: (data['pricePerToken'] as num).toDouble(), // passa de num para double 
      totalPrice: (data['totalPrice'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.open,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startupId': startupId,
      'type': type.name, // vai salvar como string (pega o nome)
      'quantity': quantity,
      'pricePerToken': pricePerToken,
      'totalPrice': totalPrice,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /*
    Logica de inversão de sinais que o Matheus comentou na aula, funciona para que um unico algoritimo de inserção
    que sempre insere em ordem crescente consiga servir tanto para as ordens de compra quanto as de venda que possuem
    logica invertida de organização (Venda: mais barato em cima / Compra: mais caro em cima)
  */


  // Isso vai ser util para dar display nos tokens no balcão (aparentemente)


  // converte lista para mapa com preços negativos
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

  // restaura os sinais
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

  // algoritmo de inserção no mapa
  static void _insertMap(Map<int, OrderModel> map, OrderModel newOrder) {
    int pos = 0;
    final list = map.values.toList();
    while (pos < list.length &&
        newOrder.pricePerToken > list[pos].pricePerToken) {
      pos++;
    }

    for (int i = map.length; i > pos; i--) {
      map[i] = map[i - 1]!; // garantir que o valor não vai ser um null
    }

    map[pos] = newOrder;
  }

  // metodo publico de inserir ordem de venda (os outros são privados pois vão entrar neste)
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

  // metodo publico de inserir ordem de compra
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
