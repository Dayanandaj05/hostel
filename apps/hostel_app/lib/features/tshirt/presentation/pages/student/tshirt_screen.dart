import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../../presentation/controllers/tshirt_controller.dart';
import '../../../../../app/app_routes.dart';

class TShirtScreen extends StatefulWidget {
  const TShirtScreen({super.key});
  @override
  State<TShirtScreen> createState() => _TShirtScreenState();
}

class _TShirtScreenState extends State<TShirtScreen> {
  String _selectedType = 'Round Neck Full Hand';
  String _selectedSize = 'M';
  int _quantity = 1;

  static const _types = ['Round Neck Full Hand', 'Collar Half Hand'];
  static const _sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
  static const _pricePerUnit = 450.0;

  static const _sizeMeasurements = {
    'XS': 'Chest: 34"',
    'S':  'Chest: 36"',
    'M':  'Chest: 38"',
    'L':  'Chest: 40"',
    'XL': 'Chest: 42"',
    'XXL': 'Chest: 44"',
    'XXXL': 'Chest: 46"',
  };

  double get _total => _pricePerUnit * _quantity;

  Future<void> _submitOrder(TShirtController controller) async {
    final userId = AuthProviderController.of(context).user?.uid;
    if (userId == null) return;

    final success = await controller.placeOrder(
      userId: userId,
      type: _selectedType,
      size: _selectedSize,
      quantity: _quantity,
      pricePerUnit: _pricePerUnit,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: Color(0xFF009688),
        ),
      );
      context.go(AppRoutes.studentMyTShirts);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage ?? 'Order failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        foregroundColor: Colors.white,
        title: const Text('Book T-Shirt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'My Orders',
            onPressed: () => context.go(AppRoutes.studentMyTShirts),
          ),
        ],
      ),
      body: Consumer<TShirtController>(
        builder: (context, controller, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // T-Shirt preview card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2137),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.checkroom_rounded, color: Colors.white, size: 72),
                      const SizedBox(height: 12),
                      Text(
                        _selectedType,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF009688),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Size: $_selectedSize  •  ₹${_total.toInt()}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Type selector
                const Text('Select Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2137))),
                const SizedBox(height: 10),
                ...(_types.map((type) => RadioListTile<String>(
                  value: type,
                  groupValue: _selectedType,
                  title: Text(type),
                  activeColor: const Color(0xFF009688),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _selectedType = v!),
                ))),
                const SizedBox(height: 16),

                // Size selector
                const Text('Select Size', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2137))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sizes.map((size) {
                    final isSelected = _selectedSize == size;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSize = size),
                      child: Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0D2137) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0D2137) : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              size,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF0D2137),
                              ),
                            ),
                            Text(
                              _sizeMeasurements[size] ?? '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                color: isSelected ? Colors.white70 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Quantity
                const Text('Quantity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2137))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _qtyBtn(Icons.remove, () { if (_quantity > 1) setState(() => _quantity--); }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('$_quantity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    _qtyBtn(Icons.add, () => setState(() => _quantity++)),
                  ],
                ),
                const SizedBox(height: 32),

                // Price summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${_pricePerUnit.toInt()} × $_quantity', style: TextStyle(color: Colors.grey.shade600)),
                      Text('₹${_total.toInt()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D2137))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: controller.isSubmitting ? null : () => _submitOrder(controller),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2137),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: controller.isSubmitting
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF0D2137).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF0D2137)),
      ),
    );
  }
}
