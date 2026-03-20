import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../../presentation/controllers/tshirt_controller.dart';

class TShirtListScreen extends StatefulWidget {
  const TShirtListScreen({super.key});

  @override
  State<TShirtListScreen> createState() => _TShirtListScreenState();
}

class _TShirtListScreenState extends State<TShirtListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = AuthProviderController.of(context).user?.uid;
      if (uid != null) {
        context.read<TShirtController>().startWatchingOrders(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        foregroundColor: Colors.white,
        title: const Text('My T-Shirt Orders'),
      ),
      body: Consumer<TShirtController>(
        builder: (context, controller, _) {
          if (controller.isLoading && controller.myOrders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.myOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checkroom_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No t-shirt orders yet',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.myOrders.length,
            itemBuilder: (context, i) {
              final order = controller.myOrders[i];
              return _TShirtOrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class _TShirtOrderCard extends StatelessWidget {
  const _TShirtOrderCard({required this.order});
  final dynamic order; // TShirtOrderModel

  @override
  Widget build(BuildContext context) {
    final status = order.status as String? ?? 'pending';
    final statusColor = switch (status.toLowerCase()) {
      'delivered' => Colors.green,
      'cancelled' => Colors.red,
      'processing' => Colors.blue,
      _ => Colors.orange,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left strip
          Container(
            width: 90,
            height: 140,
            decoration: const BoxDecoration(
              color: Color(0xFF0D2137),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.checkroom_rounded, color: Colors.white, size: 32),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 120,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.symmetric(vertical: 10),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.type as String? ?? 'T-Shirt',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0D2137),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _pill('Size: ${order.size ?? "--"}', const Color(0xFF009688)),
                      const SizedBox(width: 8),
                      _pill('Qty: ${order.quantity ?? 1}', Colors.indigo),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.currency_rupee_rounded, size: 14, color: Colors.grey),
                      Text(
                        '${(order.totalPrice as num?)?.toStringAsFixed(0) ?? "--"}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF0D2137),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (order.createdAt != null)
                    Text(
                      _fmt(order.createdAt as DateTime),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
          // QR icon
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              status == 'delivered' ? Icons.check_circle_rounded : Icons.qr_code_2_rounded,
              color: statusColor,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
