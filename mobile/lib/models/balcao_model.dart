enum ModoNegociacao { compra, venda }

enum TipoOferta { compra, venda }

class Oferta {
  final TipoOferta tipo;
  final int quantidade;
  final double preco;
  final String empresa;
  final String simbolo;
  final double variacao;
  final String volume;
  final double spread;
  final String startupId;

  // Preço mínimo permitido para ordens de compra.
  // Para venda, o usuário continua podendo definir preço abaixo ou acima.
  final double minBuyPrice;

  const Oferta({
    required this.tipo,
    required this.quantidade,
    required this.preco,
    required this.empresa,
    required this.simbolo,
    required this.variacao,
    required this.volume,
    required this.spread,
    this.startupId = '',
    this.minBuyPrice = 1.0,
  });
}

class AtivoUsuario {
  final String empresa;
  final String simbolo;
  final int quantidade;
  final double precoMedio;

  // Dados extras necessários para abrir uma ordem de venda direto pelo ativo.
  final String startupId;
  final double minBuyPrice;
  final double variacao;
  final String volume;
  final double spread;

  const AtivoUsuario({
    required this.empresa,
    required this.simbolo,
    required this.quantidade,
    required this.precoMedio,
    this.startupId = '',
    this.minBuyPrice = 1.0,
    this.variacao = 0.0,
    this.volume = '0',
    this.spread = 0.0,
  });
}
