
/* Guilherme Henrique Moreira - 25006702 */

/* 
  Enum responsável pelos modos de negociação disponíveis.
  
  compra -> usuário deseja comprar tokens
  venda  -> usuário deseja vender tokens
*/
enum ModoNegociacao { compra, venda }

/* 
  Enum utilizado para identificar o tipo de oferta
  dentro do book de ofertas.
*/
enum TipoOferta { compra, venda }

/* 
  Classe que representa uma oferta de negociação
  no balcão de investimentos.
*/
class Oferta {

  // Tipo da oferta (compra ou venda)
  final TipoOferta tipo;

  // Quantidade de tokens envolvidos na oferta
  final int quantidade;

  // Preço definido para cada token
  final double preco;

  // Nome da empresa/startup
  final String empresa;

  // Símbolo do ativo/token
  final String simbolo;

  // Variação percentual do ativo
  final double variacao;

  // Volume negociado do ativo
  final String volume;

  // Diferença entre preço de compra e venda
  final double spread;

  // ID da startup relacionada à oferta
  final String startupId;

  // ID único da oferta no banco de dados
  final String id;

  // ID do usuário que criou a oferta
  final String userId;

  // Data e horário de criação da oferta
  final DateTime? createdAt;

  // Define se a oferta foi criada pela startup
  final bool isStartup;

  /* 
    Preço mínimo permitido para ordens de compra.
    
    Em ordens de venda, o usuário pode definir
    valores acima ou abaixo normalmente.
  */
  final double minBuyPrice;

  /* 
    Construtor da classe Oferta.
    
    Alguns campos possuem valores padrão para evitar erros
    caso não sejam informados.
  */
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
    this.id = '',
    this.userId = '',
    this.createdAt,
    this.isStartup = false,
    this.minBuyPrice = 1.0,
  });
}

/* 
  Classe responsável por representar um ativo
  que pertence ao usuário.
*/
class AtivoUsuario {

  // Nome da empresa/startup
  final String empresa;

  // Símbolo do ativo/token
  final String simbolo;

  // Quantidade de tokens que o usuário possui
  final int quantidade;

  // Preço médio pago pelos tokens
  final double precoMedio;

  /* 
    Dados extras utilizados para permitir
    abertura de ordens de venda diretamente pelo ativo.
  */

  // ID da startup relacionada
  final String startupId;

  // Preço mínimo permitido para compra
  final double minBuyPrice;

  // Variação percentual do ativo
  final double variacao;

  // Volume negociado
  final String volume;

  // Spread do ativo
  final double spread;

  /* 
    Construtor da classe AtivoUsuario.
    
    Alguns campos possuem valores padrão
    para evitar problemas caso não sejam informados.
  */
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