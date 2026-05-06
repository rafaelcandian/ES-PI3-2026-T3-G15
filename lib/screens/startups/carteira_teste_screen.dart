import 'package:flutter/material.dart';
import 'package:mescla_invest/services/carteira_service.dart';
import 'package:mescla_invest/screens/auth/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CarteiraTesteScreen extends StatefulWidget {
  const CarteiraTesteScreen({super.key});

  @override
  State<CarteiraTesteScreen> createState() => _CarteiraTesteScreenState();
}

class _CarteiraTesteScreenState extends State<CarteiraTesteScreen> {
  final CarteiraService _carteira = CarteiraService();
  final TextEditingController _valorController = TextEditingController();

  double _saldoAtual = 0;
  bool _isLoading = false;

  @override
  initState() {
  super.initState();
  // Aguarda o auth estar pronto antes de carregar o saldo
  FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null).then((_) {
    _carregarSaldo();
  });
}

  Future<void> _carregarSaldo() async {
    final saldo = await _carteira.getBalance();
    setState(() => _saldoAtual = saldo);
  }

  Future<void> _adicionarSaldo() async {
    final valor = double.tryParse(_valorController.text);
    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Digite um valor valido")));
      return;
    }

    setState(() => _isLoading = true);

    final erro = await _carteira.addBalance(valor);

    setState(() => _isLoading = false);

    if (erro == null) {
      _valorController.clear();
      await _carregarSaldo();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("R\$ ${valor.toStringAsFixed(2)} adicionado")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
    }
  }

  @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: AppColors.fundo,
        appBar: AppBar(
          backgroundColor: AppColors.fundo,
          title: const Text("Teste de Carteira", style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Saldo atual
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF101731),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Saldo atual",
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      "R\$ ${_saldoAtual.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Campo de valor
              TextField(
                controller: _valorController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Valor a adicionar",
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.attach_money, color: AppColors.destaque),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botão
              SizedBox(
                width: double.infinity,
                height: 55,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _adicionarSaldo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.destaque,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          "Adicionar Saldo",
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}