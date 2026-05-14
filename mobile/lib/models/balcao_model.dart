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
  // ID do documento no Firestore — necessário para chamar a Cloud Function createOffer
  final String startupId;

  const Oferta({
    required this.tipo,
    required this.quantidade,
    required this.preco,
    required this.empresa,
    required this.simbolo,
    required this.variacao,
    required this.volume,
    required this.spread,
    this.startupId = '', // opcional: vazio para ofertas sem ID (ex: dados hardcoded)
  });
}

class AtivoUsuario {
  final String empresa;
  final String simbolo;
  final int quantidade;
  final double precoMedio;

  const AtivoUsuario({
    required this.empresa,
    required this.simbolo,
    required this.quantidade,
    required this.precoMedio,
  });
}