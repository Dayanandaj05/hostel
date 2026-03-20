import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';
import 'package:hostel_app/features/tshirt/domain/entities/tshirt_models.dart';
import 'package:hostel_app/features/tshirt/presentation/controllers/tshirt_controller.dart';

class TShirtScreen extends StatefulWidget {
  const TShirtScreen({super.key});

  @override
  State<TShirtScreen> createState() => _TShirtScreenState();
}

class _TShirtScreenState extends State<TShirtScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  TShirtStyle? _selectedStyle;
  TShirtSize? _selectedSize;
  int _quantity = 1;

  final _kNavy = const Color(0xFF0D2137);
  final _kTeal = const Color(0xFF009688);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = AuthProviderController.of(context).user;
      if (user != null) {
        context.read<TShirtController>().startWatchingOrders(user.uid);
      }
    });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        context.read<TShirtController>().clearMessages();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handlePlaceOrder() async {
    if (_selectedStyle == null || _selectedSize == null) return;

    final user = AuthProviderController.of(context).user;
    if (user == null) return;

    final success = await context.read<TShirtController>().placeOrder(
          userId: user.uid,
          style: _selectedStyle!,
          size: _selectedSize!.label,
          quantity: _quantity,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
      setState(() {
        _selectedStyle = null;
        _selectedSize = null;
        _quantity = 1;
      });
      _tabController.animateTo(1);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return '${date.day.toString().padLeft(2, '0')} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Book My T-Shirt',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          indicatorColor: _kTeal,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Book T-Shirt'),
            Tab(text: 'My Orders'),
          ],
        ),
      ),
      body: Consumer<TShirtController>(
        builder: (context, controller, child) {
          final errorMessage = controller.errorMessage;
          if (errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                  ),
                );
                controller.clearMessages();
              }
            });
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingTab(controller),
              _buildOrdersTab(controller),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingTab(TShirtController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Style Selector
          const Text(
            'Select Style',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: kTShirtStyles.map((style) {
              final isSelected = _selectedStyle?.id == style.id;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _selectedStyle = style),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected ? _kNavy.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? _kNavy : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (isSelected)
                            const Align(
                              alignment: Alignment.topRight,
                              child: Icon(Icons.check_circle, color: Color(0xFF0D2137), size: 20),
                            ),
                          Text(style.emoji, style: const TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            style.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? _kNavy : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          if (_selectedStyle != null) ...[
            const SizedBox(height: 32),
            // Section 2: Size Chart
            const Text(
              'Select Size (Size Chart)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 40,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  columns: const [
                    DataColumn(label: Text('Size')),
                    DataColumn(label: Text('Chest')),
                    DataColumn(label: Text('Length')),
                    DataColumn(label: Text('Select')),
                  ],
                  rows: kTShirtSizes.map((size) {
                    final isSelected = _selectedSize?.label == size.label;
                    return DataRow(
                      selected: isSelected,
                      color: WidgetStateProperty.resolveWith((states) {
                        if (isSelected) return _kTeal.withOpacity(0.08);
                        return null;
                      }),
                      cells: [
                        DataCell(Text(size.label, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(size.chest)),
                        DataCell(Text(size.length)),
                        DataCell(
                          Radio<String>(
                            value: size.label,
                            groupValue: _selectedSize?.label,
                            activeColor: _kTeal,
                            onChanged: (_) => setState(() => _selectedSize = size),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 32),
            // Section 3: Quantity
            const Text(
              'Quantity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _quantity < 10 ? () => setState(() => _quantity++) : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            // Section 4: Summary & Order
            if (_selectedSize != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _kNavy,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Qty: $_quantity',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 32),
                    Row(
                      children: [
                        const Icon(Icons.checkroom, color: Colors.white54, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${_selectedStyle!.name} - Size ${_selectedSize!.label}',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: controller.isPlacingOrder ? null : _handlePlaceOrder,
                        style: FilledButton.styleFrom(
                          backgroundColor: _kTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: controller.isPlacingOrder
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Place Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildOrdersTab(TShirtController controller) {
    if (controller.isLoadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.myOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No orders placed yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.myOrders.length,
      itemBuilder: (context, index) {
        final order = controller.myOrders[index];
        final style = kTShirtStyles.firstWhere((s) => s.id == order.styleId,
            orElse: () => kTShirtStyles.first);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(style.emoji, style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              order.styleName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          _buildStatusBadge(order.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Size: ${order.size}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Quantity: ${order.quantity}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ordered on ${_formatDate(order.createdAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color textColor;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = _kTeal.withValues(alpha: 0.1);
        textColor = _kTeal;
        break;
      case 'delivered':
        color = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        break;
      case 'pending':
      default:
        color = Colors.amber.withValues(alpha: 0.1);
        textColor = Colors.amber.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
