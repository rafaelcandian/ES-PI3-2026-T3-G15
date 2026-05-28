import 'package:cloud_firestore/cloud_firestore.dart';

enum WalletTransactionType { deposit, purchase, sale, withdraw }

enum WalletTransactionStatus { pending, completed, cancelled, failed }

class WalletTransactionModel {
  final String id;
  final String userId;

  /// Tipo da movimentação:
  /// deposit = entrada de dinheiro por Pix simulado
  /// purchase = compra de tokens
  /// sale = venda de tokens
  /// withdraw = saque simulado, caso vocês queiram usar depois
  final WalletTransactionType type;

  /// Status da movimentação:
  /// pending = pendente
  /// completed = concluída
  /// cancelled = cancelada
  /// failed = falhou
  final WalletTransactionStatus status;

  /// Valor da transação.
  ///
  /// Sugestão:
  /// - depósito: valor positivo
  /// - venda: valor positivo
  /// - compra: valor negativo ou valor positivo com type purchase
  ///
  /// Para facilitar o histórico visual, eu prefiro salvar compra como negativo.
  final double amount;

  /// Descrição amigável para mostrar na carteira.
  ///
  /// Exemplo:
  /// "Depósito via Pix simulado"
  /// "Compra de 50 tokens NPA"
  /// "Venda de 20 tokens NPA"
  final String description;

  /// Método usado na movimentação.
  ///
  /// Exemplo:
  /// "pix_simulado"
  /// "balcao"
  final String method;

  /// Campos opcionais para quando a transação estiver ligada a uma startup/token.
  final String? startupId;
  final String? startupName;
  final String? tokenSymbol;
  final int? tokenQuantity;
  final double? pricePerToken;

  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.amount,
    required this.description,
    required this.method,
    required this.createdAt,
    this.startupId,
    this.startupName,
    this.tokenSymbol,
    this.tokenQuantity,
    this.pricePerToken,
  });

  factory WalletTransactionModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return WalletTransactionModel(
      id: id,
      userId: data['userId'] ?? '',
      type: WalletTransactionType.values.firstWhere(
        (item) => item.name == data['type'],
        orElse: () => WalletTransactionType.deposit,
      ),
      status: WalletTransactionStatus.values.firstWhere(
        (item) => item.name == data['status'],
        orElse: () => WalletTransactionStatus.pending,
      ),
      amount: (data['amount'] as num? ?? 0).toDouble(),
      description: data['description'] ?? '',
      method: data['method'] ?? '',
      startupId: data['startupId'],
      startupName: data['startupName'],
      tokenSymbol: data['tokenSymbol'],
      tokenQuantity: data['tokenQuantity'],
      pricePerToken: (data['pricePerToken'] as num?)?.toDouble(),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'status': status.name,
      'amount': amount,
      'description': description,
      'method': method,
      'startupId': startupId,
      'startupName': startupName,
      'tokenSymbol': tokenSymbol,
      'tokenQuantity': tokenQuantity,
      'pricePerToken': pricePerToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  WalletTransactionModel copyWith({
    String? id,
    String? userId,
    WalletTransactionType? type,
    WalletTransactionStatus? status,
    double? amount,
    String? description,
    String? method,
    String? startupId,
    String? startupName,
    String? tokenSymbol,
    int? tokenQuantity,
    double? pricePerToken,
    DateTime? createdAt,
  }) {
    return WalletTransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      method: method ?? this.method,
      startupId: startupId ?? this.startupId,
      startupName: startupName ?? this.startupName,
      tokenSymbol: tokenSymbol ?? this.tokenSymbol,
      tokenQuantity: tokenQuantity ?? this.tokenQuantity,
      pricePerToken: pricePerToken ?? this.pricePerToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isEntrada {
    return type == WalletTransactionType.deposit ||
        type == WalletTransactionType.sale;
  }

  bool get isSaida {
    return type == WalletTransactionType.purchase ||
        type == WalletTransactionType.withdraw;
  }

  String get typeLabel {
    switch (type) {
      case WalletTransactionType.deposit:
        return 'Depósito';
      case WalletTransactionType.purchase:
        return 'Compra';
      case WalletTransactionType.sale:
        return 'Venda';
      case WalletTransactionType.withdraw:
        return 'Saque';
    }
  }

  String get statusLabel {
    switch (status) {
      case WalletTransactionStatus.pending:
        return 'Pendente';
      case WalletTransactionStatus.completed:
        return 'Concluída';
      case WalletTransactionStatus.cancelled:
        return 'Cancelada';
      case WalletTransactionStatus.failed:
        return 'Falhou';
    }
  }
}
