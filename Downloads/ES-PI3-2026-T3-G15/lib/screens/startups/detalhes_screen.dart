import 'package:flutter/material.dart';
import 'package:mescla_invest/screens/startups/startup_data.dart';
import 'package:mescla_invest/screens/auth/app_theme.dart';


class DetalhesStartupPage extends StatelessWidget {
  const DetalhesStartupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dynamic arguments = ModalRoute.of(context)!.settings.arguments;

    if (arguments == null || arguments is! StartupData) {
      return Scaffold(
        backgroundColor: AppColors.fundo,
        appBar: AppBar(
          title: const Text("Erro"),
          backgroundColor: AppColors.fundo,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.destaque),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: const Center(
          child: Text(
            "Startup não encontrada",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
      );
    }

    final StartupData startup = arguments;

    return Scaffold(
      backgroundColor: AppColors.fundo,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        elevation: 0,
        title: const Text(
          "Detalhes da Oferta",
          style: TextStyle(
            color: Color(0xFFFFC53D),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFC53D)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: const [
          Icon(Icons.share, size: 24),
          SizedBox(width: 15),
          Icon(Icons.notifications_none, size: 24),
          SizedBox(width: 15),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF070A1E),
        elevation: 8,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                //border color
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Vender tokens de ${startup.title}")),
                  );
                },
                child: const Text("Vender"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
        
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC53D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  foregroundColor: const Color(0xFF0F1749),
                  
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Comprar tokens para ${startup.title}")),
                  );
                },

                child: const Text("Comprar", style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // IMAGEM PRINCIPAL
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
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
                        color: const Color(0xFF1B2348),
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      );
                    },
                  ),
                  Container(
                    height: 220,
                    width: double.infinity,
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: const Color(0xFFFFC53D),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.play_arrow,
                        color: Color(0xFF0F1749),
                        size: 35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // TÍTULO
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                startup.title,
                style: const TextStyle(
                  color: Color(0xFFFFC53D),
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // SUBTÍTULO
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                startup.subtitle,
                style: const TextStyle(
                  color: Color(0xFF9CADDD),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // TAGS
            //deixar com o alinhamento à esquerda e com espaçamento entre elas
            Wrap(
              alignment: WrapAlignment.start,
              spacing: 10,
              children: [
                _buildTag(startup.tag),
                _buildTag("Série A"),
              ],
            ),

            const SizedBox(height: 25),

            // CARD DE INVESTIMENTO
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF101731),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        "Valor do Token",
                        style: TextStyle(color: Color(0xFF7D91C2)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "R\$ ${startup.tokenValue.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Color(0xFFFFC53D),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        "Meta",
                        style: TextStyle(color: Color(0xFF7D91C2)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${(startup.progress * 100).round()}%",
                        style: const TextStyle(
                          color: Color(0xFFFFC53D),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // SUMÁRIO
            _buildSectionCard(
              title: "Sumário Executivo",
              child: Text(
                "A ${startup.title} está revolucionando o setor com tecnologia inovadora. Com ${startup.tokens} tokens disponíveis e uma meta de R\$ ${startup.goal.toStringAsFixed(2)}, esta é uma oportunidade de investimento estratégica.",
                style: const TextStyle(color: Color(0xFFB0B8D1), height: 1.6),
              ),
            ),

            const SizedBox(height: 20),

            // INFORMAÇÕES
            _buildSectionCard(
              title: "Informações da Oferta",
              child: Column(
                children: [
                  _buildInfoRow("Tokens Disponíveis", startup.tokens.toString()),
                  const SizedBox(height: 12),
                  _buildInfoRow("Categoria", startup.tag),
                  const SizedBox(height: 12),
                  _buildInfoRow("Meta de Captação", "R\$ ${startup.goal.toStringAsFixed(2)}"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // FAQ
            _buildSectionCard(
              title: "Perguntas Frequentes",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Como é feito o resgate do lucro?",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Os lucros são distribuídos automaticamente nos períodos definidos.",
                    style: TextStyle(color: Color(0xFFB0B8D1), height: 1.5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Existe risco na operação?",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Como em todo investimento, existe risco. Recomendamos análise prévia.",
                    style: TextStyle(color: Color(0xFFB0B8D1), height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  static Widget _buildTag(String text) {
    return Chip(
      label: Text(text),
      backgroundColor: const Color(0xFF2E3B7C),
      //colocar borda com radius circular
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      //colocar borda com cor amarela
      side: const BorderSide(color: Color(0xFF2E3B7C)),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
    );
  }

  static Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101731),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFFC53D),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF7D91C2), fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}