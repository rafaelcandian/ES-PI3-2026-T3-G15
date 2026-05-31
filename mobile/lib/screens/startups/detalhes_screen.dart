/* Victória Nobre - 25016398 */
/* Guilherme Henrique Moreira - 25006702 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mescla_invest/widgets/shared/page_header.dart';
import 'package:mescla_invest/screens/startups/startup_data.dart';
import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/services/pergunta_service.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';
import 'package:mescla_invest/widgets/shared/app_button.dart';
import 'package:mescla_invest/screens/startups/startup_video_screen.dart';

import '../../models/balcao_model.dart';
import '../ordens/ordem_exe_screen.dart';

/* Página de Detalhes da Startup: Centraliza Pitch, Métricas de Captação e Governança.
   A implementação do "Canal do Investidor" valida a posse de tokens para liberar 
   comunicação privada, simulando um ambiente real de relacionamento com investidores. */
class DetalhesStartupPage extends StatefulWidget {
  const DetalhesStartupPage({super.key});

  @override
  State<DetalhesStartupPage> createState() => _DetalhesStartupPageState();
}

class _DetalhesStartupPageState extends State<DetalhesStartupPage> {
  final PerguntaService _perguntaService = PerguntaService();

  /* Controllers para gestão de inputs de comunicação com a startup. */
  final TextEditingController _perguntaPrivadaController =
  TextEditingController();
  final TextEditingController _perguntaPublicaController =
  TextEditingController();

  List<Map<String, dynamic>> _perguntas = [];

  bool _carregandoPerguntas = true;
  bool _carregandoVerificacao = true;
  bool _temTokenDaStartup = false;
  bool _verificacaoIniciada = false;
  bool _enviandoPerguntaPrivada = false;
  bool _enviandoPerguntaPublica = false;

  @override
  void dispose() {
    _perguntaPrivadaController.dispose();
    _perguntaPublicaController.dispose();
    super.dispose();
  }

  /* Controla o acesso ao canal privado conforme os tokens do usuário. */
  Future<void> _verificarSeUsuarioTemToken(String startupId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || startupId.isEmpty) {
        if (!mounted) return;

        setState(() {
          _temTokenDaStartup = false;
          _carregandoVerificacao = false;
        });

        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      final data = doc.data();

      final Map<String, dynamic> tokens =
          data?['tokens'] as Map<String, dynamic>? ?? {};

      final int quantidadeTokens = (tokens[startupId] as num?)?.toInt() ?? 0;

      if (!mounted) return;

      setState(() {
        _temTokenDaStartup = doc.exists && quantidadeTokens > 0;
        _carregandoVerificacao = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _temTokenDaStartup = false;
        _carregandoVerificacao = false;
      });
    }
  }

  /* Carrega perguntas públicas e privadas vinculadas à startup. */
  Future<void> _carregarPerguntas(String startupId) async {
    if (!mounted) return;

    setState(() {
      _carregandoPerguntas = true;
    });

    final perguntas = await _perguntaService.buscarPerguntas(startupId);

    if (!mounted) return;

    setState(() {
      _perguntas = perguntas;
      _carregandoPerguntas = false;
    });
  }

  /* Envia pergunta pública visível para todos os usuários da tela. */
  Future<void> _enviarPerguntaPublica(StartupData startup) async {
    final texto = _perguntaPublicaController.text.trim();

    if (texto.isEmpty) {
      _mostrarSnackBar('Digite uma pergunta antes de enviar.');
      return;
    }

    setState(() {
      _enviandoPerguntaPublica = true;
    });

    final error = await _perguntaService.enviarPergunta(
      startupId: startup.id,
      texto: texto,
      isPrivada: false,
    );

    if (!mounted) return;

    setState(() {
      _enviandoPerguntaPublica = false;
    });

    if (error == null) {
      _perguntaPublicaController.clear();
      _mostrarSnackBar('Pergunta enviada com sucesso.');
      _carregarPerguntas(startup.id);
    } else {
      _mostrarSnackBar(error);
    }
  }

  /* Envia pergunta privada apenas quando o usuário possui tokens da startup. */
  Future<void> _enviarPerguntaPrivada(StartupData startup) async {
    final texto = _perguntaPrivadaController.text.trim();

    if (texto.isEmpty) {
      _mostrarSnackBar('Digite uma pergunta antes de enviar.');
      return;
    }

    setState(() {
      _enviandoPerguntaPrivada = true;
    });

    final error = await _perguntaService.enviarPergunta(
      startupId: startup.id,
      texto: texto,
      isPrivada: true,
    );

    if (!mounted) return;

    setState(() {
      _enviandoPerguntaPrivada = false;
    });

    if (error == null) {
      _perguntaPrivadaController.clear();
      _mostrarSnackBar('Pergunta privada enviada com sucesso.');
      _carregarPerguntas(startup.id);
    } else {
      _mostrarSnackBar(error);
    }
  }

  void _mostrarSnackBar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          mensagem,
          style: const TextStyle(
            color: AppColors.textoPrincipal,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamic arguments = ModalRoute.of(context)!.settings.arguments;

    if (arguments == null || arguments is! StartupData) {
      return const Scaffold(
        backgroundColor: AppColors.fundo,
        body: Center(
          child: Text(
            'Startup não encontrada',
            style: TextStyle(color: AppColors.textoPrincipal),
          ),
        ),
      );
    }

    final StartupData startup = arguments;

    final totalTokens =
    startup.totalTokens <= 0 ? startup.tokens : startup.totalTokens;
    final soldTokens = (totalTokens - startup.tokens).clamp(0, totalTokens);
    final captacaoProgress = totalTokens <= 0 ? 0.0 : soldTokens / totalTokens;
    final captacaoPercent = (captacaoProgress * 100).round();
    final valorCaptado = soldTokens * startup.minBuyPrice;

    if (!_verificacaoIniciada) {
      _verificacaoIniciada = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verificarSeUsuarioTemToken(startup.id);
        _carregarPerguntas(startup.id);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.fundo,
      extendBody: false,
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: _InvestBottomBar(
        onInvestir: () => _abrirOrdemCompra(context, startup),
      ),
      body: Stack(
        children: [
          const _AtmosphericBackground(),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: startup.title,
                  subtitle: startup.subtitle,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildTag(startup.tag),
                    _buildTag(startup.stage),
                    _buildTag(startup.market),
                    _buildTag(
                      startup.status == 'open'
                          ? 'Rodada aberta'
                          : 'Rodada encerrada',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _HeroImage(startup: startup),
                const SizedBox(height: 24),
                _MetricCard(
                  startup: startup,
                  captacaoProgress: captacaoProgress,
                  captacaoPercent: captacaoPercent,
                  valorCaptado: valorCaptado,
                ),
                const SizedBox(height: 22),
                _buildSectionCard(
                  title: 'Descrição',
                  child: Text(
                    startup.description.isNotEmpty
                        ? startup.description
                        : 'Startup sem descrição cadastrada.',
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.7,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildSectionCard(
                  title: 'Informações da Oferta',
                  child: Column(
                    children: [
                      _buildInfoRow('Mercado', startup.market),
                      const SizedBox(height: 12),
                      _buildInfoRow('Categoria', startup.tag),
                      const SizedBox(height: 12),
                      _buildInfoRow('Estágio', startup.stage),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Tokens disponíveis',
                        startup.tokens.toString(),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Total de tokens',
                        startup.totalTokens.toString(),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Investidores',
                        startup.investorsCount.toString(),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Valor do token',
                        'R\$ ${startup.minBuyPrice.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Investimento mínimo',
                        startup.investimentoMinimo > 0
                            ? 'R\$ ${startup.investimentoMinimo.toStringAsFixed(2)}'
                            : 'Sem mínimo',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Valuation',
                        'R\$ ${startup.valuation.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Meta de captação',
                        'R\$ ${startup.goal.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _buildSectionCard(
                  title: 'Sócios',
                  child: startup.partners.isEmpty
                      ? const Text(
                    'Nenhum sócio cadastrado para esta startup.',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                      : Column(
                    children: List.generate(
                      startup.partners.length,
                          (index) {
                        final partner = startup.partners[index];

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                            index == startup.partners.length - 1
                                ? 0
                                : 12,
                          ),
                          child: _buildPartnerCard(
                            name: partner.name,
                            role: partner.role,
                            equityPercent: partner.equityPercent,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildSectionCard(
                  title: 'Pitch Deck',
                  child: const _PitchDeckTile(),
                ),
                const SizedBox(height: 18),
                _buildSectionCard(
                  title: 'Perguntas',
                  child: Column(
                    children: [
                      if (_carregandoPerguntas)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.destaque,
                            ),
                          ),
                        )
                      else if (_perguntas.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Nenhuma pergunta ainda.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        ..._perguntas.map((p) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildQuestionCard(
                              usuario: p['autorNome'] ?? 'Usuário',
                              tempo: _formatarTempo(p['createdAt']),
                              pergunta: p['texto'] ?? '',
                              resposta: p['isPrivada'] == true
                                  ? 'Pergunta enviada pelo Canal do Investidor.'
                                  : 'Aguardando resposta da startup...',
                            ),
                          );
                        }).toList(),
                      const SizedBox(height: 20),
                      _PublicQuestionInput(
                        controller: _perguntaPublicaController,
                        loading: _enviandoPerguntaPublica,
                        onTap: _enviandoPerguntaPublica
                            ? null
                            : () => _enviarPerguntaPublica(startup),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _buildSectionCard(
                  title: 'Canal do Investidor',
                  child: _buildCanalInvestidorContent(context, startup),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _abrirOrdemCompra(BuildContext context, StartupData startup) {
    final simbolo = _gerarSimbolo(startup.title);

    final ofertaPrincipal = Oferta(
      tipo: TipoOferta.venda,
      quantidade: startup.tokens,
      preco: startup.minBuyPrice,
      empresa: startup.title,
      simbolo: simbolo,
      variacao: 0,
      volume: '${startup.tokens}',
      spread: 0.0,
      startupId: startup.id,
      minBuyPrice: startup.minBuyPrice,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrdemExeScreen(
          oferta: ofertaPrincipal,
          modo: ModoNegociacao.compra,
          ofertasDisponiveis: [ofertaPrincipal],
          investimentoMinimo: startup.investimentoMinimo,
          compraDireto: true,
        ),
      ),
    );
  }

  String _gerarSimbolo(String nome) {
    final palavras = nome
        .replaceAll(RegExp(r'[^a-zA-ZÀ-ÿ0-9 ]'), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (palavras.isEmpty) return 'STP';

    if (palavras.length == 1) {
      final palavra = palavras.first;
      final tamanho = palavra.length < 3 ? palavra.length : 3;

      return palavra.substring(0, tamanho).toUpperCase();
    }

    return palavras.take(3).map((p) => p[0]).join().toUpperCase();
  }

  static String _formatarTempo(dynamic createdAt) {
    if (createdAt == null) return '';

    DateTime? data;

    if (createdAt is Timestamp) {
      data = createdAt.toDate();
    } else if (createdAt is int) {
      data = DateTime.fromMillisecondsSinceEpoch(createdAt);
    } else if (createdAt is String) {
      data = DateTime.tryParse(createdAt);
    } else if (createdAt is Map) {
      final seconds = createdAt['_seconds'] ?? createdAt['seconds'] ?? 0;
      data = DateTime.fromMillisecondsSinceEpoch((seconds as int) * 1000);
    }

    if (data == null) return '';

    final diferenca = DateTime.now().difference(data);

    if (diferenca.inDays > 0) return 'há ${diferenca.inDays} d';
    if (diferenca.inHours > 0) return 'há ${diferenca.inHours} h';
    if (diferenca.inMinutes > 0) return 'há ${diferenca.inMinutes} min';

    return 'agora';
  }

  Widget _buildCanalInvestidorContent(
      BuildContext context,
      StartupData startup,
      ) {
    if (_carregandoVerificacao) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: CircularProgressIndicator(color: AppColors.destaque),
        ),
      );
    }

    if (_temTokenDaStartup) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Você possui tokens desta startup. O canal privado está liberado.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _perguntaPrivadaController,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 4,
            cursorColor: AppColors.destaque,
            decoration: InputDecoration(
              hintText: 'Envie uma pergunta privada para a startup...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.45),
              ),
            ),
          ),
          const SizedBox(height: 14),
          AppButton.primary(
            label: 'Enviar pergunta privada',
            loading: _enviandoPerguntaPrivada,
            onTap: _enviandoPerguntaPrivada
                ? null
                : () => _enviarPerguntaPrivada(startup),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: premiumFieldDecoration(radius: 16),
      child: const Text(
        'O canal privado é exclusivo para investidores.',
        style: TextStyle(
          color: Colors.white70,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: premiumFieldDecoration(radius: 50),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: premiumCardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  String _iniciaisSocio(String nome) {
    final partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();

    if (partes.isEmpty) return 'S';

    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }

    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  /* Apresenta o quadro societário e a distribuição de equity da startup. */
  Widget _buildPartnerCard({
    required String name,
    required String role,
    required double equityPercent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardElevado.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.destaque.withOpacity(0.16),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.destaque.withOpacity(0.10),
              border: Border.all(
                color: AppColors.destaque.withOpacity(0.20),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                _iniciaisSocio(name),
                style: const TextStyle(
                  color: AppColors.destaque,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role.isEmpty ? 'Sócio da startup' : role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.destaque.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.destaque.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: Text(
              '${equityPercent.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: AppColors.destaque,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: premiumFieldDecoration(radius: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard({
    required String usuario,
    required String tempo,
    required String pergunta,
    required String resposta,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: premiumFieldDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: AppColors.destaque,
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                usuario,
                style: const TextStyle(
                  color: AppColors.destaque,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tempo,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pergunta,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              resposta,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* Fundo atmosférico usado para manter o padrão visual premium. */
class _AtmosphericBackground extends StatelessWidget {
  const _AtmosphericBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.azul.withOpacity(0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 240,
            left: -130,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.destaque.withOpacity(0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 90,
            right: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.roxo.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final StartupData startup;

  const _HeroImage({
    required this.startup,
  });

  void _abrirVideo(BuildContext context) {
    if (startup.video.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vídeo não cadastrado para esta startup.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StartupVideoScreen(
          title: startup.title,
          videoUrl: startup.video,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: premiumCardDecoration(radius: 26),
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.network(
              startup.image,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 220,
                  width: double.infinity,
                  color: AppColors.campo,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textoMuitoFraco,
                    size: 34,
                  ),
                );
              },
            ),
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.72),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _abrirVideo(context),
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.destaqueClaro,
                      AppColors.destaqueEscuro,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.destaque.withOpacity(0.30),
                      blurRadius: 26,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.fundo,
                  size: 42,
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      startup.video.trim().isEmpty
                          ? 'Vídeo não cadastrado'
                          : 'Assistir pitch da startup',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.videocam_rounded,
                    color: AppColors.destaque,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* Exibe o progresso da captação e o valor unitário do token. */
class _MetricCard extends StatelessWidget {
  final StartupData startup;
  final double captacaoProgress;
  final int captacaoPercent;
  final double valorCaptado;

  const _MetricCard({
    required this.startup,
    required this.captacaoProgress,
    required this.captacaoPercent,
    required this.valorCaptado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: premiumCardDecoration(radius: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricColumn(
                  label: 'Valor do Token',
                  value: 'R\$ ${startup.minBuyPrice.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricColumn(
                  label: 'Captação',
                  value: '$captacaoPercent%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricColumn(
                  label: 'Investimento mínimo',
                  value: startup.investimentoMinimo > 0
                      ? 'R\$ ${startup.investimentoMinimo.toStringAsFixed(2)}'
                      : 'Sem mínimo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: captacaoProgress.clamp(0.0, 1.0),
              backgroundColor: AppColors.campo,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.destaque,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Captado',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'R\$ ${valorCaptado.toStringAsFixed(2)} / R\$ ${startup.goal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;

  const _MetricColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: premiumFieldDecoration(radius: 16),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.destaque,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicQuestionInput extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback? onTap;

  const _PublicQuestionInput({
    required this.controller,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: AppColors.destaque,
          decoration: InputDecoration(
            hintText: 'Envie uma pergunta pública...',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.45),
            ),
          ),
        ),
        const SizedBox(height: 14),
        AppButton.primary(
          label: 'Enviar pergunta',
          loading: loading,
          onTap: loading ? null : onTap,
        ),
      ],
    );
  }
}

/* Call to action fixo para facilitar o início do investimento. */
class _InvestBottomBar extends StatelessWidget {
  final VoidCallback onInvestir;

  const _InvestBottomBar({
    required this.onInvestir,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.fundo.withOpacity(0.98),
          border: Border(
            top: BorderSide(
              color: AppColors.bordaClara.withOpacity(0.8),
            ),
          ),
        ),
        child: AppButton.primary(
          label: 'Investir na startup',
          icon: Icons.trending_up_rounded,
          onTap: onInvestir,
        ),
      ),
    );
  }
}

/* Card informativo do pitch deck sem depender de campo extra no modelo StartupData. */
class _PitchDeckTile extends StatelessWidget {
  const _PitchDeckTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: premiumFieldDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.destaque.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.destaque.withOpacity(0.26),
              ),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.destaque,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Pitch deck disponível para análise da startup.',
              style: TextStyle(
                color: AppColors.textoPrincipal,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}