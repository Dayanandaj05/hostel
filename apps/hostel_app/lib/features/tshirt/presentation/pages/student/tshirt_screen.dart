import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../../core/design/psg_design_system.dart';
import '../../../../../core/widgets/static_nav_bar.dart';
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
    'S': 'Chest: 36"',
    'M': 'Chest: 38"',
    'L': 'Chest: 40"',
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
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          title: 'Book T-Shirt',
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: PsgColors.primary,
              size: 20,
            ),
            onPressed: () => context.go(AppRoutes.studentHome),
          ),
          actions: [
            IconButton(
              icon:
                  const Icon(Icons.list_alt_rounded, color: PsgColors.primary),
              tooltip: 'My Orders',
              onPressed: () => context.go(AppRoutes.studentMyTShirts),
            ),
          ],
        ),
        body: Consumer<TShirtController>(
          builder: (context, controller, _) {
            return ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 88,
                16,
                StaticNavBar.reservedBottomPadding(context) + 16,
              ),
              children: [
                GlassCard(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.checkroom_rounded,
                        color: PsgColors.primary,
                        size: 70,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedType,
                        style: PsgText.headline(
                          18,
                          weight: FontWeight.w800,
                          color: PsgColors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: PsgColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Size: $_selectedSize  •  ₹${_total.toInt()}',
                          style: PsgText.label(11, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Type',
                        style: PsgText.headline(
                          16,
                          weight: FontWeight.w800,
                          color: PsgColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._types.map(
                        (type) => InkWell(
                          onTap: () => setState(() => _selectedType = type),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedType == type
                                  ? PsgColors.primary.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedType == type
                                    ? PsgColors.primary
                                    : PsgColors.outline.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedType == type
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 18,
                                  color: _selectedType == type
                                      ? PsgColors.primary
                                      : PsgColors.outline,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    type,
                                    style: PsgText.body(
                                      14,
                                      weight: _selectedType == type
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: PsgColors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Size',
                        style: PsgText.headline(
                          16,
                          weight: FontWeight.w800,
                          color: PsgColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _sizes.map((size) {
                          final isSelected = _selectedSize == size;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedSize = size),
                            child: Container(
                              width: 64,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? PsgColors.primary
                                    : Colors.white.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? PsgColors.primary
                                      : PsgColors.outline
                                          .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    size,
                                    textAlign: TextAlign.center,
                                    style: PsgText.label(
                                      12,
                                      color: isSelected
                                          ? Colors.white
                                          : PsgColors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    _sizeMeasurements[size] ?? '',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isSelected
                                          ? Colors.white70
                                          : PsgColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Quantity',
                        style: PsgText.headline(
                          16,
                          weight: FontWeight.w800,
                          color: PsgColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _qtyBtn(
                            Icons.remove,
                            () {
                              if (_quantity > 1) setState(() => _quantity--);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              '$_quantity',
                              style: PsgText.headline(
                                22,
                                color: PsgColors.primary,
                              ),
                            ),
                          ),
                          _qtyBtn(Icons.add, () => setState(() => _quantity++)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${_pricePerUnit.toInt()} × $_quantity',
                        style: PsgText.body(
                          13,
                          color: PsgColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '₹${_total.toInt()}',
                        style: PsgText.headline(24, color: PsgColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: controller.isSubmitting
                        ? null
                        : () => _submitOrder(controller),
                    style: FilledButton.styleFrom(
                      backgroundColor: PsgColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Place Order',
                            style: PsgText.label(14, color: Colors.white),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: PsgColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: PsgColors.primary),
      ),
    );
  }
}
