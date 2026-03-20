import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../../domain/entities/food_token_model.dart';
import '../../../presentation/controllers/food_token_controller.dart';

class MyTokensScreen extends StatefulWidget {
  const MyTokensScreen({super.key});
  @override
  State<MyTokensScreen> createState() => _MyTokensScreenState();
}

class _MyTokensScreenState extends State<MyTokensScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = AuthProviderController.of(context).user?.uid;
      if (uid != null) context.read<FoodTokenController>().startWatchingTokens(uid);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        foregroundColor: Colors.white,
        title: const Text('My Tokens'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: const Color(0xFF009688),
          tabs: const [Tab(text: 'Active'), Tab(text: 'History')],
        ),
      ),
      body: Consumer<FoodTokenController>(
        builder: (context, controller, _) {
          if (controller.isLoading && controller.myTokens.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final active = controller.myTokens.where((t) => t.status == FoodTokenStatus.active).toList();
          final history = controller.myTokens.where((t) => t.status != FoodTokenStatus.active).toList();
          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(active, 'No active tokens'),
              _buildList(history, 'No token history'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<FoodTokenModel> tokens, String emptyMsg) {
    if (tokens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fastfood_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyMsg, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tokens.length,
      itemBuilder: (_, i) => _TokenCard(token: tokens[i]),
    );
  }
}

class _TokenCard extends StatelessWidget {
  const _TokenCard({required this.token});
  final FoodTokenModel token;

  @override
  Widget build(BuildContext context) {
    final isActive = token.status == FoodTokenStatus.active;
    final statusColor = isActive ? const Color(0xFF009688) : Colors.grey;
    final mealIcon = switch ((token.mealSlot ?? '').toLowerCase()) {
      String s when s.contains('breakfast') => Icons.free_breakfast_rounded,
      String s when s.contains('dinner') => Icons.dinner_dining_rounded,
      _ => Icons.lunch_dining_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 80, height: 120,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF0D2137) : Colors.grey.shade400,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(mealIcon, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF009688) : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(isActive ? 'ACTIVE' : 'USED',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 100, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(vertical: 10)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(token.itemName ?? 'Food Item',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D2137))),
                  const SizedBox(height: 4),
                  Text(token.mealSlot ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _pill('Qty: ${token.quantity ?? 1}', Colors.indigo),
                      const SizedBox(width: 8),
                      _pill('₹${token.totalPrice?.toStringAsFixed(0) ?? '--'}', const Color(0xFF009688)),
                    ],
                  ),
                  if (token.scheduledDate != null) ...[
                    const SizedBox(height: 6),
                    Text(_fmt(token.scheduledDate!), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Icon(isActive ? Icons.qr_code_2_rounded : Icons.check_circle_rounded, color: statusColor, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
  );

  String _fmt(DateTime dt) => '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
}
