import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/models/order_model.dart';
import 'package:mescla_invest/services/balcao_service.dart';
import 'package:mescla_invest/services/carteira_service.dart';
import 'package:mescla_invest/themes/app_theme.dart';

/*
  Tela feita com IA sem nenhuma revisão apenas para teste dos metodos criados em relação
  ao balcão de tokens
*/

class BalcaoTesteScreen extends StatefulWidget {
  const BalcaoTesteScreen({super.key});

  @override
  State<BalcaoTesteScreen> createState() => _BalcaoTesteScreenState();
}

class _BalcaoTesteScreenState extends State<BalcaoTesteScreen> {
  final BalcaoService _balcao = BalcaoService();
  final CarteiraService _carteira = CarteiraService();

  // Startups disponíveis para teste
  final List<Map<String, String>> _startups = [
    {'id': 'shoplink',  'nome': 'ShopLink Digital'},
    {'id': 'finnova',   'nome': 'FinNova Bank Tech'},
    {'id': 'logismart', 'nome': 'LogiSmart Solutions'},
  ];

  String _startupSelecionada = 'shoplink';
  double _saldo = 0;
  Map<String, dynamic> _tokens = {};
  List<OrderModel> _ordensCompra = [];
  List<OrderModel> _ordensVenda = [];
  List<String> _logs = [];
  bool _carregando = false;
  Timer? _timer;
  int _contadorTimer = 5;

  @override
  void initState() {
    super.initState();
    _atualizarCarteira();
    _iniciarTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ─── Timer ───────────────────────────────────────────────

  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _contadorTimer--);
      if (_contadorTimer <= 0) {
        _contadorTimer = 5;
        _buscarOrdens();
      }
    });
  }

  // ─── Carteira ────────────────────────────────────────────

  Future<void> _atualizarCarteira() async {
    final saldo = await _carteira.getBalance();
    final tokens = await _carteira.getTokens();
    setState(() {
      _saldo = saldo;
      _tokens = tokens;
    });
  }

  // ─── Ordens ──────────────────────────────────────────────

  Future<void> _buscarOrdens() async {
    final ordens = await _balcao.getOpenedOrders(_startupSelecionada); // 👈 correto
    setState(() {
      _ordensCompra = ordens[OrderType.buy.name] ?? [];
      _ordensVenda = ordens[OrderType.sell.name] ?? [];
    });
    _log("🔄 Ordens atualizadas — ${_ordensCompra.length} compras | ${_ordensVenda.length} vendas");
  }

  Future<void> _criarOfertaCompra() async {
    setState(() => _carregando = true);
    final erro = await _balcao.createPurchaseOffer(
      startupId: _startupSelecionada,
      quantity: 5,
      pricePerToken: 1.00,
    );
    setState(() => _carregando = false);
    if (erro == null) {
      _log("✅ Oferta de COMPRA criada — 5 tokens @ R\$ 1,00");
      await _atualizarCarteira();
      await _buscarOrdens();
    } else {
      _log("❌ Erro na compra: $erro");
    }
  }

  Future<void> _criarOfertaVenda() async {
    setState(() => _carregando = true);
    final erro = await _balcao.createSellOffer(
      startupId: _startupSelecionada,
      quantity: 5,
      pricePerToken: 1.00,
    );
    setState(() => _carregando = false);
    if (erro == null) {
      _log("✅ Oferta de VENDA criada — 5 tokens @ R\$ 1,00");
      await _atualizarCarteira();
      await _buscarOrdens();
    } else {
      _log("❌ Erro na venda: $erro");
    }
  }

  // ─── Log ─────────────────────────────────────────────────

  void _log(String mensagem) {
    final hora = TimeOfDay.now().format(context);
    setState(() {
      _logs.insert(0, "[$hora] $mensagem");
      if (_logs.length > 20) _logs.removeLast();
    });
  }

  // ─── UI ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        title: const Text(
          "🧪 Teste do Balcão",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Timer visual
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF101731),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: AppColors.destaque, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "${_contadorTimer}s",
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Usuário atual ──
            _buildCard(
              titulo: "👤 Usuário Atual",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "UID: ${FirebaseAuth.instance.currentUser?.uid ?? 'não logado'}",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildChip("💰 Saldo", "R\$ ${_saldo.toStringAsFixed(2)}"),
                      _buildChip(
                        "🪙 Tokens ($_startupSelecionada)",
                        "${_tokens[_startupSelecionada] ?? 0}",
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _atualizarCarteira,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text("Atualizar carteira"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.destaque,
                        side: const BorderSide(color: AppColors.destaque),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Selector de startup ──
            _buildCard(
              titulo: "🏢 Startup para teste",
              child: Column(
                children: _startups.map((s) {
                  final selecionada = s['id'] == _startupSelecionada;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _startupSelecionada = s['id']!);
                      _buscarOrdens();
                      _log("📌 Startup trocada para ${s['nome']}");
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selecionada
                            ? AppColors.destaque.withOpacity(0.15)
                            : const Color(0xFF0B132F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selecionada
                              ? AppColors.destaque
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s['nome']!,
                            style: TextStyle(
                              color: selecionada
                                  ? AppColors.destaque
                                  : Colors.white70,
                              fontWeight: selecionada
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (selecionada)
                            const Icon(Icons.check_circle,
                                color: AppColors.destaque, size: 18),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // ── Botões de teste ──
            _buildCard(
              titulo: "🧪 Ações de Teste (5 tokens @ R\$ 1,00)",
              child: _carregando
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.destaque,
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _criarOfertaCompra,
                            icon: const Icon(Icons.arrow_upward, size: 16),
                            label: const Text("Criar COMPRA"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A3A2A),
                              foregroundColor: const Color(0xFF43D672),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                    color: Color(0xFF43D672)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _criarOfertaVenda,
                            icon: const Icon(Icons.arrow_downward, size: 16),
                            label: const Text("Criar VENDA"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3A1A1A),
                              foregroundColor: const Color(0xFFEC5D71),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                    color: Color(0xFFEC5D71)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 12),

            // ── Listas de ordens ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildListaOrdens(
                    titulo: "📗 Compras",
                    ordens: _ordensCompra,
                    cor: const Color(0xFF43D672),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildListaOrdens(
                    titulo: "📕 Vendas",
                    ordens: _ordensVenda,
                    cor: const Color(0xFFEC5D71),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Log ──
            _buildCard(
              titulo: "📋 Log de Operações",
              child: _logs.isEmpty
                  ? const Text(
                      "Nenhuma operação ainda.",
                      style: TextStyle(color: Colors.white38),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _logs
                          .map(
                            (log) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                log,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Widgets auxiliares ───────────────────────────────────

  Widget _buildCard({required String titulo, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101731),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: AppColors.destaque,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildChip(String label, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(valor,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildListaOrdens({
    required String titulo,
    required List<OrderModel> ordens,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101731),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: TextStyle(
                  color: cor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 8),
          if (ordens.isEmpty)
            const Text("Vazio",
                style: TextStyle(color: Colors.white38, fontSize: 12))
          else
            ...ordens.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${o.quantity}x",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    Text(
                      "R\$ ${o.pricePerToken.toStringAsFixed(2)}",
                      style: TextStyle(
                          color: cor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}