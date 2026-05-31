/* Victória Nobre - 25016398 */

/* 
  Classe responsável por representar um ativo/token 
  que o usuário possui em sua carteira de investimentos.
*/
class AtivoCarteira {
  
  // ID da startup relacionada ao ativo
  final String startupId;

  // Nome da startup
  final String nome;

  // Símbolo do ativo/token
  final String simbolo;

  // Quantidade de tokens que o usuário possui
  final int tokens;

  // Valor atual de cada token
  final double valorToken;

  // Preço médio pago pelo usuário ao comprar os tokens
  final double precoMedio;

  // Variação percentual do ativo
  final double variacao;

  // Volume de negociações do ativo
  final String volume;

  // Diferença entre compra e venda do ativo
  final double spread;

  /* 
    Construtor da classe.
    Todos os campos são obrigatórios.
  */
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

  /* 
    Calcula o valor total investido atualmente no ativo.
    
    Fórmula:
    quantidade de tokens × valor atual do token
  */
  double get valorTotal => tokens * valorToken;

  /* 
    Calcula o lucro ou prejuízo do usuário.
    
    Fórmula:
    (valor atual - preço médio) × quantidade de tokens
  */
  double get lucroPrejuizo => (valorToken - precoMedio) * tokens;
}