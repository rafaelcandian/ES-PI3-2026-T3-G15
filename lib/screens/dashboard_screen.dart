import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/screens/auth/app_theme.dart';
import 'package:mescla_invest/widgets/bottom_nav_bar.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            PopupMenuButton<String>(
              color: const Color(0xFF182051),
              position: PopupMenuPosition.under,
              onSelected: (String result) {
                if (result == 'logout') {
                  _handleLogout(context);
                } else if (result == 'perfil') {
                  Navigator.pushNamed(context, '/perfil');
                } else if (result == 'notificacoes') {
                  Navigator.pushNamed(context, '/notificacoes');
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'notificacoes',
                  child: Row(
                    children: [
                      Icon(Icons.notifications_none, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Notificações', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuDivider(color: Color.fromARGB(33, 255, 255, 255)),
                const PopupMenuItem<String>(
                  value: 'perfil',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Ver Perfil', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuDivider(color: Color.fromARGB(33, 255, 255, 255)),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sair', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF182051),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildPerformanceCard(),
              const SizedBox(height: 20),
              _buildTokensCard(),
              const SizedBox(height: 20),
              _buildOpportunityCard(),
              const SizedBox(height: 20),
              _buildHistoryCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard',
          style: TextStyle(
            color: AppColors.destaque,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF101731),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Patrimônio Total',
                style: TextStyle(color: Color(0xFF7D91C2), fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                'R\$ 142.850,00',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.arrow_upward, color: Color(0xFF43D672), size: 18),
                  SizedBox(width: 6),
                  Text(
                    '+12,4% Lucro este mês',
                    style: TextStyle(color: Color(0xFF43D672), fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _buildPeriodButton('Dia', true),
                  const SizedBox(width: 10),
                  _buildPeriodButton('Semana', false),
                  const SizedBox(width: 10),
                  _buildPeriodButton('Mês', false),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF101731),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Desempenho da Carteira',
                style: TextStyle(
                  color: AppColors.destaque,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.bar_chart, color: AppColors.destaque),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Evolução baseada em valuation de startups investidas',
            style: TextStyle(color: Color(0xFF9CADDD), height: 1.6),
          ),
          const SizedBox(height: 18),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF0B132F),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PerformanceChartPainter(),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A3D),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Hoje R\$ 2.410,00',
                      style: TextStyle(color: AppColors.destaque, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokensCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF101731),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Meus Tokens',
                style: TextStyle(
                  color: AppColors.destaque,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'VER TODOS',
                style: TextStyle(
                  color: Color(0xFF5F7BC6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildTokenRow('SolarGrid AI', 'R\$ 12.400', '+8.2%'),
          const SizedBox(height: 14),
          _buildTokenRow('BioNexus Lab', 'R\$ 8.920', '+6.1%'),
          const SizedBox(height: 16),
          _buildTokenRow('EcoFreight', 'R\$ 4.150', '-2.4%', isNegative: true),
        ],
      ),
    );
  }

  Widget _buildOpportunityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFEFCD57).withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Novas Oportunidades',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Duas novas startups de Fintech entraram na fase de captação hoje.',
            style: TextStyle(color: Color(0xFFB0B8D1), height: 1.5),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destaque,
              foregroundColor: AppColors.fundo,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Explorar Startups'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF101731),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Histórico de Proventos',
            style: TextStyle(
              color: AppColors.destaque,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildHistoryRow('12 Out, 2023', 'SolarGrid AI', 'Royalties Trimestrais'),
          const SizedBox(height: 16),
          _buildHistoryRow('05 Out, 2023', 'EcoFreight', 'Dividendos Mensais'),
          const SizedBox(height: 16),
          _buildHistoryRow('28 Set, 2023', 'BioNexus Lab', 'Bonificação'),
        ],
      ),
    );
  }

  Widget _buildTokenRow(String name, String value, String gain, {bool isNegative = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('320 Tokens', style: TextStyle(color: Color(0xFF7D91C2), fontSize: 12)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                gain,
                style: TextStyle(
                  color: isNegative ? const Color(0xFFEC5D71) : const Color(0xFF43D672),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(String date, String startup, String type) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF131A3D),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.wallet, color: AppColors.destaque, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(color: Color(0xFF7D91C2), fontSize: 12)),
              const SizedBox(height: 4),
              Text(startup, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Text(type, style: const TextStyle(color: Color(0xFF9CADDD), fontSize: 12)),
      ],
    );
  }

  Widget _buildPeriodButton(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.destaque : const Color(0xFF0B132F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.fundo : Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PerformanceChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E3B7C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.6, size.width * 0.35, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.82, size.width * 0.65, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.42, size.width, size.height * 0.5);

    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = AppColors.destaque;
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.74), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.7), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.62), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.5), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
