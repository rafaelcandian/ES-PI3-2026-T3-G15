import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mescla_invest/screens/startups/startup_data.dart';
import 'package:mescla_invest/widgets/bottom_nav_bar.dart';
import 'package:mescla_invest/screens/startups/startup_card.dart'; // Certifique-se de que a importação está correta!

class _C {
  static const bg = Color(0xFF020818);
  static const surface = Color(0xFF0B1230);
  static const surfaceRaised = Color(0xFF0F1840);
  static const gold = Color(0xFFEFCD57);
  static const goldDim = Color(0xFFB89A2E);
  static const white = Colors.white;
  static const white70 = Colors.white70;
  static const white38 = Colors.white38;
  static const white12 = Colors.white12;
  static const white06 = Color(0x0FFFFFFF);
}

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> with TickerProviderStateMixin {
  String _stage = 'Todas';
  String _area = 'Todas';
  double _walletBalance = 0.0; // Variável para o saldo da carteira

  late AnimationController _headerAnim;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  final CollectionReference _startupsRef = FirebaseFirestore.instance.collection('startups');
  final CollectionReference _usersRef = FirebaseFirestore.instance.collection('users'); // Supondo que o saldo esteja na coleção "users"

  final List<String> _stages = ['Todas', 'Nova', 'Operação', 'Expansão'];
  final List<String> _areas = ['Todas', 'Tecnologia', 'Educação', 'Saúde', 'Financeiro', 'Agronegócio'];

  @override
  void initState() {
    super.initState();
    _getWalletBalance(); // Carregar o saldo da carteira ao iniciar
    _headerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.18), end: Offset.zero).animate(CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut));
    _headerAnim.forward();
  }

  // Função para obter o saldo da carteira do usuário
  void _getWalletBalance() async {
    try {
      String userId = "user123"; // Substitua por FirebaseAuth.instance.currentUser?.uid;
      DocumentSnapshot userDoc = await _usersRef.doc(userId).get();

      if (userDoc.exists) {
        setState(() {
          _walletBalance = userDoc['walletBalance'] ?? 0.0; // A propriedade 'walletBalance' deve existir no Firestore
        });
      }
    } catch (e) {
      print("Erro ao obter saldo da carteira: $e");
    }
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      extendBody: true, // Faz o conteúdo passar atrás da nav bar flutuante
      bottomNavigationBar: const BottomNavBar(selectedIndex: 0),
      body: Stack(
        children: [
          _buildAtmosphericBg(),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                _buildWalletBalance(), // Exibir o saldo da carteira
                _buildFilters(), // Filtros agora na mesma linha
                Expanded(child: _buildList()), // Atualize a lista de startups com os dados convertidos
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Background atmosférico
  Widget _buildAtmosphericBg() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1A3A8F).withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _C.gold.withOpacity(0.07),
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

  // ── Top bar
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'),
          ),
          const Text(
            'Catálogo de Startups', // Alterado para o nome correto
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: 16,
            ),
          ),
          const Icon(Icons.account_circle, color: Colors.white, size: 28),
        ],
      ),
    );
  }

  // ── Exibição do saldo da carteira
  Widget _buildWalletBalance() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Saldo da Carteira",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                "R\$ ${_walletBalance.toStringAsFixed(2)}",  // Exibe o saldo com duas casas decimais
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Filtros na mesma linha, agora com labels
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDropdownWithLabel('Estado da Startup', _stages, _stage, (value) {
            setState(() {
              _stage = value;
            });
          }),
          _buildDropdownWithLabel('Área de Atuação', _areas, _area, (value) {
            setState(() {
              _area = value;
            });
          }),
        ],
      ),
    );
  }

  // ── Filtro dropdown com label
  Widget _buildDropdownWithLabel(String label, List<String> items, String selectedValue, ValueChanged<String> onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: selectedValue,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white),
          dropdownColor: _C.surface,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? value) {
            if (value != null) {
              onSelect(value); // Chama a função onSelect com o valor selecionado
            }
          },
        ),
      ],
    );
  }

  // ── Lista de startups
  Widget _buildList() {
    Query query = _startupsRef;
    if (_stage != 'Todas') query = query.where('stage', isEqualTo: _stage);
    if (_area != 'Todas') query = query.where('area', isEqualTo: _area);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = StartupData.fromFirestore(docs[index]);
            return StartupCard(data: data); // Passando os dados convertidos
          },
        );
      },
    );
  }
}