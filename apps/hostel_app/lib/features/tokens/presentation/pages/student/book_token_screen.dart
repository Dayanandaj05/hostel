import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../../presentation/controllers/food_token_controller.dart';
import '../../../../../app/app_routes.dart';

class BookTokenScreen extends StatefulWidget {
  const BookTokenScreen({super.key});
  @override
  State<BookTokenScreen> createState() => _BookTokenScreenState();
}

class _BookTokenScreenState extends State<BookTokenScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedMeal = 'Lunch';
  final Map<String, int> _cart = {};

  static const _meals = ['Breakfast', 'Lunch', 'Dinner'];

  static const _menuItems = [
    _MenuItem('Gobi Chilli', 40.0, Icons.local_dining_rounded),
    _MenuItem('Chicken Gravy', 80.0, Icons.set_meal_rounded),
    _MenuItem('Mushroom Manchurian', 60.0, Icons.eco_rounded),
    _MenuItem('Omelette', 10.0, Icons.egg_alt_rounded),
    _MenuItem('Boiled Egg', 10.0, Icons.egg_rounded),
    _MenuItem('Full Boil Egg', 10.0, Icons.egg_rounded),
    _MenuItem('Egg Gravy', 25.0, Icons.soup_kitchen_rounded),
  ];

  double get _cartTotal => _cart.entries.fold(0, (sum, e) {
        final item = _menuItems.firstWhere((m) => m.name == e.key);
        return sum + item.price * e.value;
      });

  int get _cartCount => _cart.values.fold(0, (sum, qty) => sum + qty);

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _checkout(FoodTokenController controller) async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item to your cart.')),
      );
      return;
    }

    final userId = AuthProviderController.of(context).user?.uid;
    if (userId == null) return;

    bool allSuccess = true;
    for (final entry in _cart.entries) {
      final item = _menuItems.firstWhere((m) => m.name == entry.key);
      final success = await controller.bookToken(
        userId: userId,
        itemName: item.name,
        itemPrice: item.price,
        quantity: entry.value,
        mealSlot: _selectedMeal,
        scheduledDate: _selectedDate,
      );
      if (!success) { allSuccess = false; break; }
    }

    if (!mounted) return;
    if (allSuccess) {
      setState(() => _cart.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tokens booked successfully!'),
          backgroundColor: Color(0xFF009688),
        ),
      );
      context.go(AppRoutes.studentMyTokens);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage ?? 'Booking failed.')),
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
        title: const Text('Book Food Token'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'My Tokens',
            onPressed: () => context.go(AppRoutes.studentMyTokens),
          ),
        ],
      ),
      body: Consumer<FoodTokenController>(
        builder: (context, controller, _) {
          return Column(
            children: [
              // Date & meal selector
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF009688)),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedMeal,
                        isDense: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.restaurant_rounded, color: Color(0xFF009688), size: 18),
                        ),
                        items: _meals.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (v) => setState(() => _selectedMeal = v!),
                      ),
                    ),
                  ],
                ),
              ),
              // Menu items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, i) {
                    final item = _menuItems[i];
                    final qty = _cart[item.name] ?? 0;
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF009688).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(item.icon, color: const Color(0xFF009688), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('₹${item.price.toInt()}', style: const TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                if (qty > 0) ...[
                                  _circleBtn(Icons.remove, () => setState(() {
                                    if (qty == 1) _cart.remove(item.name);
                                    else _cart[item.name] = qty - 1;
                                  })),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                ],
                                _circleBtn(Icons.add, () => setState(() => _cart[item.name] = qty + 1), primary: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Cart summary + checkout
              if (_cartCount > 0)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$_cartCount item${_cartCount > 1 ? 's' : ''}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          Text('₹${_cartTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0D2137))),
                        ],
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: controller.isSubmitting ? null : () => _checkout(controller),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0D2137),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: controller.isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Book Tokens', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {bool primary = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primary ? const Color(0xFF0D2137) : Colors.grey.shade200,
        ),
        child: Icon(icon, size: 16, color: primary ? Colors.white : const Color(0xFF0D2137)),
      ),
    );
  }
}

class _MenuItem {
  final String name;
  final double price;
  final IconData icon;
  const _MenuItem(this.name, this.price, this.icon);
}
