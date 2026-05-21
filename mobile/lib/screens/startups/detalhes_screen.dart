import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mescla_invest/screens/startups/startup_data.dart';
import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/services/pergunta_privada.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';
import 'package:mescla_invest/screens/startups/startup_video_screen.dart';

import '../../models/balcao_model.dart';
import '../ordens/ordem_exe_screen.dart';

class DetalhesStartupPage extends StatefulWidget {
  const DetalhesStartupPage({super.key});

  @override
  State<DetalhesStartupPage> createState() => _DetalhesStartupPageState();
}

class _DetalhesStartupPageState extends State<DetalhesStartupPage> {
  final PerguntaPrivadaService _perguntaPrivadaService =
      PerguntaPrivadaService();

  final TextEditingController _perguntaPrivadaController =
      TextEditingController();

  bool _carregandoVerificacao = true;
  bool _temTokenDaStartup = false;
  bool _verificacaoIniciada = false;
  bool _enviandoPerguntaPrivada = false;

  @override
  void dispose() {
    _perguntaPrivadaController.dispose();
    super.dispose();
  }

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
          .collection('ativos')
          .doc(startupId)
          .get();

      final data = doc.data();

      final int quantidadeTokens =
          (data?['quantidadeTokens'] as num?)?.toInt() ?? 0;

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

  Future<void> _enviarPerguntaPrivada(StartupData startup) async {
    final texto = _perguntaPrivadaController.text.trim();

    if (texto.isEmpty) {
      _mostrarSnackBar('Digite uma pergunta antes de enviar.');
      return;
    }

    setState(() {
      _enviandoPerguntaPrivada = true;
    });

    try {
      await _perguntaPrivadaService.enviarPerguntaPrivada(
        startupId: startup.id,
        startupNome: startup.title,
        pergunta: texto,
      );

      _perguntaPrivadaController.clear();

      if (!mounted) return;

      _mostrarSnackBar('Pergunta privada enviada com sucesso.');
    } catch (_) {
      if (!mounted) return;

      _mostrarSnackBar('Erro ao enviar pergunta privada.');
    } finally {
      if (!mounted) return;

      setState(() {
        _enviandoPerguntaPrivada = false;
      });
    }
  }

  void _mostrarSnackBar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Text(
          mensagem,
          style: const TextStyle(
            color: AppColors.textoPrincipal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamic arguments = ModalRoute.of(context)!.settings.arguments;

    if (arguments == null || arguments is! StartupData) {
      return Scaffold(
        backgroundColor: AppColors.fundo,
        body: const Center(
          child: Text(
            'Startup não encontrada',
            style: TextStyle(
              color: AppColors.textoPrincipal,
            ),
          ),
        ),
      );
    }

    final StartupData startup = arguments;

    if (!_verificacaoIniciada) {
      _verificacaoIniciada = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verificarSeUsuarioTemToken(startup.id);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.fundo,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        elevation: 0,
        title: const Text(
          'Sobre a Startup',
          style: TextStyle(
            color: AppColors.destaque,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.destaque,
        ),
        actions: [
          IconButton(
            onPressed: () {
              _mostrarSnackBar(
                'Compartilhamento disponível em breve.',
              );
            },
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.destaque,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _InvestBottomBar(
        onInvestir: () => _abrirOrdemCompra(context, startup),
      ),
      body: Stack(
        children: [
          const _AtmosphericBackground(),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroImage(startup: startup),

                const SizedBox(height: 24),

                const PremiumHeaderEyebrow(
                  text: 'DETALHES DA STARTUP',
                ),

                const SizedBox(height: 14),

                Text(
                  startup.title,
                  style: const TextStyle(
                    color: AppColors.destaque,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  startup.subtitle,
                  style: const TextStyle(
                    color: AppColors.textoFraco,
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
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

                _MetricCard(startup: startup),

                const SizedBox(height: 22),

                _buildSectionCard(
                  title: 'Descrição',
                  child: Text(
                    startup.description.isNotEmpty
                        ? startup.description
                        : 'Startup sem descrição cadastrada.',
                    style: const TextStyle(
                      color: AppColors.textoFraco,
                      height: 1.7,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                _buildSectionCard(
                  title: 'Informações da Oferta',
                  child: Column(
                    children: [
                      _buildInfoRow(
                        'Mercado',
                        startup.market,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Categoria',
                        startup.tag,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Estágio',
                        startup.stage,
                      ),
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
                        'R\$ ${startup.tokenValue.toStringAsFixed(2)}',
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
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Equity',
                        '${startup.equity.toStringAsFixed(1)}%',
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
                            color: AppColors.textoFraco,
                            height: 1.5,
                            fontSize: 14,
                          ),
                        )
                      : Column(
                          children: List.generate(
                            startup.partners.length,
                            (index) {
                              final partner = startup.partners[index];

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == startup.partners.length - 1
                                      ? 0
                                      : 12,
                                ),
                                child: _buildInfoRow(
                                  '${partner.name} • ${partner.role}',
                                  '${partner.equityPercent.toStringAsFixed(1)}%',
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
                  title: 'Perguntas Públicas',
                  child: Column(
                    children: [
                      _buildQuestionCard(
                        usuario: 'Carlos',
                        tempo: 'há 2 dias',
                        pergunta:
                            'Existe previsão de expansão internacional?',
                        resposta:
                            'Estamos estruturando entrada em mercados da América Latina.',
                      ),
                      const SizedBox(height: 14),
                      _buildQuestionCard(
                        usuario: 'Fernanda',
                        tempo: 'há 5 dias',
                        pergunta:
                            'A startup pretende abrir nova rodada?',
                        resposta:
                            'Existe possibilidade de Série B após encerramento da rodada atual.',
                      ),
                      const SizedBox(height: 20),
                      const _PublicQuestionInput(),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                _buildSectionCard(
                  title: 'Canal do Investidor',
                  child: _buildCanalInvestidorContent(
                    context,
                    startup,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _abrirOrdemCompra(
  BuildContext context,
  StartupData startup,
) {
  final simbolo = _gerarSimbolo(startup.title);

  final ofertaPrincipal = Oferta(
    tipo: TipoOferta.venda,
    quantidade: startup.tokens,
    preco: startup.tokenValue,
    empresa: startup.title,
    simbolo: simbolo,
    variacao: 0,
    volume: '${startup.tokens}',
    spread: 0.4,
    startupId: startup.id,
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

      return palavra
          .substring(0, palavra.length.clamp(1, 3))
          .toUpperCase();
    }

    return palavras.take(3).map((p) => p[0]).join().toUpperCase();
  }

  Widget _buildCanalInvestidorContent(
    BuildContext context,
    StartupData startup,
  ) {
    if (_carregandoVerificacao) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: CircularProgressIndicator(
            color: AppColors.destaque,
          ),
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
              color: AppColors.textoFraco,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _perguntaPrivadaController,
            style: const TextStyle(
              color: AppColors.textoPrincipal,
            ),
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Envie uma pergunta privada para a startup...',
            ),
          ),
          const SizedBox(height: 14),
          _PrimaryGradientButton(
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
      decoration: premiumFieldDecoration(
        radius: 16,
      ),
      child: const Text(
        'O canal privado é exclusivo para investidores.',
        style: TextStyle(
          color: AppColors.textoFraco,
          height: 1.5,
        ),
      ),
    );
  }

  static Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: premiumFieldDecoration(
        radius: 50,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textoPrincipal,
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
      decoration: premiumCardDecoration(
        radius: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumHeaderEyebrow(
            text: title.toUpperCase(),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  static Widget _buildInfoRow(
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: premiumFieldDecoration(
        radius: 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textoFraco,
                fontSize: 13,
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
                color: AppColors.textoPrincipal,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildQuestionCard({
    required String usuario,
    required String tempo,
    required String pergunta,
    required String resposta,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: premiumFieldDecoration(
        radius: 18,
      ),
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
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tempo,
                style: const TextStyle(
                  color: AppColors.textoMuitoFraco,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pergunta,
            style: const TextStyle(
              color: AppColors.textoPrincipal,
              fontWeight: FontWeight.w900,
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
                color: AppColors.textoFraco,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AtmosphericBackground extends StatelessWidget {
  const _AtmosphericBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(),
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
      decoration: premiumCardDecoration(
        radius: 26,
      ),
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
                    Colors.black.withOpacity(0.68),
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
                        color: AppColors.textoPrincipal,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
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

class _MetricCard extends StatelessWidget {
  final StartupData startup;

  const _MetricCard({
    required this.startup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: premiumCardDecoration(
        radius: 24,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricColumn(
                  label: 'Valor do Token',
                  value:
                      'R\$ ${startup.tokenValue.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricColumn(
                  label: 'Captação',
                  value:
                      '${(startup.progress * 100).toStringAsFixed(0)}%',
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
              value: startup.progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.campo,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.destaque,
              ),
            ),
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
      decoration: premiumFieldDecoration(
        radius: 16,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textoMuitoFraco,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.destaque,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PitchDeckTile extends StatelessWidget {
  const _PitchDeckTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: premiumFieldDecoration(
        radius: 18,
      ),
      child: const Row(
        children: [
          Icon(
            Icons.picture_as_pdf_rounded,
            color: AppColors.destaque,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pitch Deck disponível em breve',
              style: TextStyle(
                color: AppColors.textoPrincipal,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicQuestionInput extends StatelessWidget {
  const _PublicQuestionInput();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TextField(
          maxLines: 3,
          style: TextStyle(
            color: AppColors.textoPrincipal,
          ),
          decoration: InputDecoration(
            hintText: 'Envie uma pergunta pública...',
          ),
        ),
        const SizedBox(height: 14),
        _PrimaryGradientButton(
          label: 'Enviar pergunta',
          onTap: null,
        ),
      ],
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _PrimaryGradientButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        child: loading
            ? const CircularProgressIndicator()
            : Text(label),
      ),
    );
  }
}

class _InvestBottomBar extends StatelessWidget {
  final VoidCallback onInvestir;

  const _InvestBottomBar({
    required this.onInvestir,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _PrimaryGradientButton(
          label: 'Investir na startup',
          onTap: onInvestir,
        ),
      ),
    );
  }
}