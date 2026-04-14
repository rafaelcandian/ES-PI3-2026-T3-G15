import 'package:flutter/material.dart';
import 'package:mescla_invest/screens/startups/startup_data.dart';


class DetalhesStartupPage extends StatelessWidget {
  const DetalhesStartupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final StartupData startup = ModalRoute.of(context)!.settings.arguments as StartupData;

    return Scaffold(
      backgroundColor: const Color(0xFF10184e),
      appBar: AppBar(
        title: Text(startup.title),
        backgroundColor: const Color(0xFF10184e),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(startup.image, height: 200, width: double.infinity, fit: BoxFit.cover),

              const SizedBox(height: 20),

              Text(
                startup.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                startup.subtitle,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),

              const SizedBox(height: 20),

              Text(
                "Valor do Token: ${startup.tokenValue}",
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),

              const SizedBox(height: 10),

              Text(
                "Progresso: ${ (startup.progress * 100).toStringAsFixed(0)}% (${startup.goal})",
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),

              const SizedBox(height: 20),

              const Text(
                "Sumário Executivo",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "A ${startup.title} está revolucionando...", // Conteúdo mais detalhado aqui
                style: const TextStyle(color: Colors.white),
              ),

              const SizedBox(height: 20),

              Text(
                "Crescimento: ${startup.tag}",
                style: const TextStyle(color: Colors.white),
              ),

              const SizedBox(height: 10),

              Text(
                "Tokens disponíveis: ${startup.tokens}",
                style: const TextStyle(color: Colors.white),
              ),

              const SizedBox(height: 30),

              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Lógica para comprar tokens
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Comprar tokens para ${startup.title}")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 50,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(\'Comprar tokens\'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}