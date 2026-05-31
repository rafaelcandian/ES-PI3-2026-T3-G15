/* Victória Nobre - 25016398 */


import 'package:cloud_firestore/cloud_firestore.dart';

/* 
  Enum responsável pelos tipos de movimentações
  possíveis dentro da carteira do usuário.
*/
enum WalletTransactionType {
  deposit,   // Depósito de saldo
  purchase,  // Compra de tokens
  sale,      // Venda de tokens
  withdraw,  // Saque de saldo
}

/* 
  Enum responsável pelos possíveis status
  de uma movimentação financeira.
*/
enum WalletTransactionStatus {
  pending,    // Pendente
  completed,  // Concluída
  cancelled,  // Cancelada
  failed,     // Falhou
}

/* 
  Classe responsável por representar uma movimentação
  financeira dentro da carteira do usuário.
*/
class WalletTransactionModel {

  // ID único da transação
  final String id;

  // ID do usuário dono da transação
  final String userId;

  /* 
    Tipo da movimentação:
    
    deposit  -> entrada de dinheiro
    purchase -> compra de tokens
    sale     -> venda de tokens
    withdraw -> saque
  */
  final WalletTransactionType type;

  /* 
    Status atual da movimentação:
    
    pending   -> pendente
    completed -> concluída
    cancelled -> cancelada
    failed    -> falhou
  */
  final WalletTransactionStatus status;

  /* 
    Valor da transação.
    
    Sugestão usada no sistema:
    - depósito = valor positivo
    - venda = valor positivo
    - compra = valor negativo
  */
  final double amount;

  /* 
    Descrição amigável da movimentação.
    
    Exemplos:
    "Compra de 10 tokens"
    "Depósito via Pix"
  */
  final String description;

  /* 
    Método utilizado na movimentação.
    
    Exemplos:
    "pix_simulado"
    "balcao"
  */
  final String method;

  /* 
    Campos opcionais relacionados a startup/token.
    
    São usados apenas quando a transação
    envolve compra ou venda de ativos.
  */
  final String? startupId;
  final String? startupName;
  final String? tokenSymbol;
  final int? tokenQuantity;
  final double? pricePerToken;

  // Data de criação da transação
  final DateTime createdAt;

  /* Construtor da classe */
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

  /* 
    Converte os dados vindos do Firestore
    para um objeto WalletTransactionModel.
  */
  factory WalletTransactionModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return WalletTransactionModel(
      id: id,

      // Busca o ID do usuário
      userId: data['userId'] ?? '',

      // Converte o texto salvo no banco para enum
      type: WalletTransactionType.values.firstWhere(
        (item) => item.name == data['type'],
        orElse: () => WalletTransactionType.deposit,
      ),

      // Converte o status salvo no banco para enum
      status: WalletTransactionStatus.values.firstWhere(
        (item) => item.name == data['status'],
        orElse: () => WalletTransactionStatus.pending,
      ),

      // Converte valores numéricos para double
      amount: (data['amount'] as num? ?? 0).toDouble(),

      description: data['description'] ?? '',
      method: data['method'] ?? '',

      // Dados opcionais relacionados ao token
      startupId: data['startupId'],
      startupName: data['startupName'],
      tokenSymbol: data['tokenSymbol'],
      tokenQuantity: data['tokenQuantity'],
      pricePerToken: (data['pricePerToken'] as num?)?.toDouble(),

      // Converte Timestamp do Firestore para DateTime
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /* 
    Converte o objeto para Map,
    permitindo salvar no Firestore.
  */
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

      // Salva a data no formato Timestamp do Firestore
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /* 
    Método utilizado para criar uma cópia
    do objeto alterando apenas alguns campos.
  */
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

  /* 
    Verifica se a movimentação representa
    entrada de dinheiro na carteira.
  */
  bool get isEntrada {
    return type == WalletTransactionType.deposit ||
        type == WalletTransactionType.sale;
  }

  /* 
    Verifica se a movimentação representa
    saída de dinheiro da carteira.
  */
  bool get isSaida {
    return type == WalletTransactionType.purchase ||
        type == WalletTransactionType.withdraw;
  }

  /* 
    Retorna um texto amigável para o tipo
    da movimentação.
  */
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

  /* 
    Retorna um texto amigável para o status
    da movimentação.
  */
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