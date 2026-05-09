import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mescla_invest/screens/startups/startup_data.dart';
import 'package:mescla_invest/screens/auth/app_theme.dart';
import 'package:mescla_invest/services/pergunta_privada.dart';

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
    } catch (e) {
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
        backgroundColor: AppColors.fundoEscuro,
        appBar: AppBar(
          title: const Text('Erro'),
          backgroundColor: AppColors.fundoEscuro,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.destaque,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Startup não encontrada',
            style: TextStyle(
              fontSize: 20,
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
      backgroundColor: AppColors.fundoEscuro,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.fundoEscuro,
        elevation: 0,
        title: const Text(
          'Sobre a Startup',
          style: TextStyle(
            color: AppColors.destaque,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.destaque,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _mostrarSnackBar('Compartilhamento disponível em breve.');
            },
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.destaque,
            ),
          ),
          const SizedBox(width: 8),
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
                  ),
                ),

                const SizedBox(height: 16),

                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildTag(startup.tag),
                    _buildTag('Série A'),
                    _buildTag('Rodada aberta'),
                  ],
                ),

                const SizedBox(height: 24),

                _MetricCard(startup: startup),

                const SizedBox(height: 22),

                _buildSectionCard(
                  title: 'Sumário Executivo',
                  child: Text(
                    'A ${startup.title} está revolucionando o setor com tecnologia inovadora. '
                        'Com ${startup.tokens} tokens disponíveis e uma meta de R\$ ${startup.goal.toStringAsFixed(2)}, '
                        'esta é uma oportunidade de investimento estratégica dentro do ecossistema MESCLA.',
                    style: const TextStyle(
                      color: AppColors.textoFraco,
                      height: 1.6,
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
                        'Tokens disponíveis',
                        startup.tokens.toString(),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Categoria',
                        startup.tag,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Valor do token',
                        'R\$ ${startup.tokenValue.toStringAsFixed(2)}',
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
                  title: 'Pitch Deck',
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.campo,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.bordaClara,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.destaque.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.destaque.withOpacity(0.28),
                            ),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: AppColors.destaque,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pitch Deck 2026',
                                style: TextStyle(
                                  color: AppColors.textoPrincipal,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Apresentação institucional da startup',
                                style: TextStyle(
                                  color: AppColors.textoMuitoFraco,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: null,
                          icon: Icon(
                            Icons.download_rounded,
                            color: AppColors.textoMuitoFraco,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                _buildSectionCard(
                  title: 'Perguntas Públicas',
                  child: Column(
                    children: [
                      _buildQuestionCard(
                        usuario: 'Carlos',
                        tempo: 'há 2 dias',
                        pergunta: 'Existe previsão de expansão internacional?',
                        resposta:
                        'Estamos estruturando entrada em mercados da América Latina em 2027.',
                      ),
                      const SizedBox(height: 14),
                      _buildQuestionCard(
                        usuario: 'Fernanda',
                        tempo: 'há 5 dias',
                        pergunta: 'A startup pretende abrir nova rodada?',
                        resposta:
                        'Existe possibilidade de Série B após encerramento da rodada atual.',
                      ),
                      const SizedBox(height: 14),
                      _buildQuestionCard(
                        usuario: 'Ricardo',
                        tempo: 'há 1 semana',
                        pergunta: 'Como funciona a valorização dos tokens?',
                        resposta:
                        'A valorização acompanha as negociações simuladas dentro da plataforma.',
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        style: const TextStyle(
                          color: AppColors.textoPrincipal,
                        ),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Envie uma pergunta pública...',
                          hintStyle: const TextStyle(
                            color: AppColors.textoMuitoFraco,
                          ),
                          filled: true,
                          fillColor: AppColors.campo,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.bordaClara,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppColors.destaque.withOpacity(0.55),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.destaqueClaro,
                                AppColors.destaqueEscuro,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {},
                              child: const Center(
                                child: Text(
                                  'Enviar pergunta',
                                  style: TextStyle(
                                    color: AppColors.card,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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
      preco: startup.tokenValue,
      empresa: startup.title,
      simbolo: simbolo,
      variacao: 0,
      volume: '${startup.tokens}',
      spread: 0.4,
    );

    final ofertasDisponiveis = [
      ofertaPrincipal,
      Oferta(
        tipo: TipoOferta.venda,
        quantidade: (startup.tokens * 0.70).round(),
        preco: startup.tokenValue + 0.45,
        empresa: startup.title,
        simbolo: simbolo,
        variacao: 0.8,
        volume: '${(startup.tokens * 0.70).round()}',
        spread: 0.6,
      ),
      Oferta(
        tipo: TipoOferta.venda,
        quantidade: (startup.tokens * 0.45).round(),
        preco: startup.tokenValue + 0.90,
        empresa: startup.title,
        simbolo: simbolo,
        variacao: 1.2,
        volume: '${(startup.tokens * 0.45).round()}',
        spread: 0.9,
      ),
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrdemExeScreen(
          oferta: ofertaPrincipal,
          modo: ModoNegociacao.compra,
          ofertasDisponiveis: ofertasDisponiveis,
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
      return palavras.first
          .substring(0, palavras.first.length.clamp(1, 3))
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
            'Você possui tokens desta startup. O canal privado está liberado para enviar perguntas exclusivas e conversar diretamente com os fundadores.',
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
            decoration: InputDecoration(
              hintText: 'Envie uma pergunta privada para a startup...',
              hintStyle: const TextStyle(
                color: AppColors.textoMuitoFraco,
              ),
              filled: true,
              fillColor: AppColors.campo,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.bordaClara,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.destaque.withOpacity(0.55),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.destaqueClaro,
                    AppColors.destaqueEscuro,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _enviandoPerguntaPrivada
                      ? null
                      : () => _enviarPerguntaPrivada(startup),
                  child: Center(
                    child: _enviandoPerguntaPrivada
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.card,
                      ),
                    )
                        : const Text(
                      'Enviar pergunta privada',
                      style: TextStyle(
                        color: AppColors.card,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          _buildBotaoChatPrivado(context, startup),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.campo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.bordaClara,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: AppColors.destaque,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'O canal privado é exclusivo para investidores. Invista nesta startup para liberar o envio de perguntas privadas e o chat com os fundadores.',
              style: TextStyle(
                color: AppColors.textoFraco,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoChatPrivado(
      BuildContext context,
      StartupData startup,
      ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.destaqueClaro,
            AppColors.destaqueEscuro,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/chat_privado',
              arguments: startup,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_open_rounded,
                  color: AppColors.card,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Abrir chat privado',
                    style: TextStyle(
                      color: AppColors.card,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.card,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildTag(String text) {
    return Chip(
      label: Text(text),
      backgroundColor: AppColors.campo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      side: const BorderSide(
        color: AppColors.bordaClara,
      ),
      labelStyle: const TextStyle(
        color: AppColors.textoPrincipal,
        fontSize: 12,
        fontWeight: FontWeight.w700,
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
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.bordaClara,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textoFraco,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textoPrincipal,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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
      decoration: BoxDecoration(
        color: AppColors.campo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.bordaClara,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                  color: AppColors.textoMuitoFraco,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            pergunta,
            style: const TextStyle(
              color: AppColors.textoPrincipal,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.bordaClara,
              ),
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
      child: Stack(
        children: [
          Positioned(
            top: -130,
            right: -100,
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.azul.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -120,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.destaque.withOpacity(0.06),
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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
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
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.55),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Container(
            width: 70,
            height: 70,
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
                  color: AppColors.destaque.withOpacity(0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.card,
                size: 38,
              ),
            ),
          ),
        ],
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
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.bordaClara,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricColumn(
                  label: 'Valor do Token',
                  value: 'R\$ ${startup.tokenValue.toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _MetricColumn(
                  label: 'Meta',
                  value: '${(startup.progress * 100).round()}%',
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
    return Column(
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
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.destaque,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.destaque,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
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
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border(
            top: BorderSide(
              color: AppColors.bordaClara,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.40),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.destaqueClaro,
                  AppColors.destaqueEscuro,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.destaque.withOpacity(0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onInvestir,
                child: const Center(
                  child: Text(
                    'Investir na startup',
                    style: TextStyle(
                      color: AppColors.card,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}