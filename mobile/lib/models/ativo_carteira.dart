class AtivoCarteira {
  final String startupId;
  final String nome;
  final String simbolo;
  final int tokens;
  final double valorToken;
  final double precoMedio;
  final double variacao;
  final String volume;
  final double spread;

  const AtivoCarteira({
    required this.startupId,
    required this.nome,
    required this.simbolo,
    required this.tokens,
    required this.valorToken,
    required this.precoMedio,
    required this.variacao,
    required this.volume,
    required this.spread,
  });

  double get valorTotal => tokens * valorToken;

  double get lucroPrejuizo => (valorToken - precoMedio) * tokens;
}