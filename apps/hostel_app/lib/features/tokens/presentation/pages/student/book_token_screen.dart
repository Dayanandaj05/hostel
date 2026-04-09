import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:hostel_app/app/app_routes.dart';
import 'package:hostel_app/core/design/psg_design_system.dart';
import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';
import 'package:hostel_app/features/tokens/presentation/controllers/food_token_controller.dart';

class BookTokenScreen extends StatefulWidget {
  const BookTokenScreen({super.key});

  @override
  State<BookTokenScreen> createState() => _BookTokenScreenState();
}

class _BookTokenScreenState extends State<BookTokenScreen> {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedMeal = 'Lunch';
  final Map<String, int> _quantities = {};

  static const _meals = ['Breakfast', 'Lunch', 'Dinner'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(
      () => setState(() => _scrollOffset = _scrollController.offset),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _menuStream() {
    return FirebaseFirestore.instance
        .collection('mess_menu')
        .where('mealSlot', isEqualTo: _selectedMeal)
        .where('isAvailable', isEqualTo: true)
        .snapshots();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _bookItem(
    FoodTokenController controller,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final uid = AuthProviderController.of(context).user?.uid;
    if (uid == null) return;

    final data = doc.data();
    final qty = _quantities[doc.id] ?? 1;
    if (qty <= 0) return;

    final success = await controller.bookToken(
      userId: uid,
      itemName: data['itemName'] as String? ?? 'Unknown Item',
      itemPrice: ((data['price'] as num?) ?? 0).toDouble(),
      quantity: qty,
      mealSlot: _selectedMeal,
      scheduledDate: _selectedDate,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token booked successfully!'),
          backgroundColor: PsgColors.green,
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
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          scrollOffset: _scrollOffset,
          title: 'Book Food Token',
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: PsgColors.primary,
              size: 20,
            ),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.studentHome),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.receipt_long_rounded,
                color: PsgColors.primary,
              ),
              tooltip: 'My Tokens',
              onPressed: () => context.go(AppRoutes.studentMyTokens),
            ),
          ],
        ),
        body: Consumer<FoodTokenController>(
          builder: (context, controller, _) {
            return ListView(
              controller: _scrollController,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 88,
                bottom: 32,
                left: 16,
                right: 16,
              ),
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: PsgColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd MMM yyyy')
                                      .format(_selectedDate),
                                  style: PsgText.body(
                                    13,
                                    color: PsgColors.onSurface,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedMeal,
                          isDense: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.35),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: PsgText.body(
                            13,
                            color: PsgColors.onSurface,
                            weight: FontWeight.w600,
                          ),
                          items: _meals
                              .map((m) =>
                                  DropdownMenuItem(value: m, child: Text(m)))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _selectedMeal = v;
                              _quantities.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const PsgSectionHeader(title: 'Available Menu Items'),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _menuStream(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Text(
                          'Failed to load menu items.',
                          style: PsgText.body(14, color: PsgColors.error),
                        ),
                      );
                    }

                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No items available for $_selectedMeal.',
                            style: PsgText.body(
                              14,
                              color: PsgColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: docs.map((doc) {
                        final data = doc.data();
                        final itemName =
                            data['itemName'] as String? ?? 'Menu Item';
                        final price = ((data['price'] as num?) ?? 0).toDouble();
                        final isVeg = (data['isVeg'] as bool?) ?? true;
                        final maxQty = ((data['maxQty'] as num?) ?? 5).toInt();
                        final emoji = (data['emoji'] as String?)?.trim();
                        final qty = _quantities[doc.id] ?? 1;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: PsgColors.primary
                                            .withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        (emoji != null && emoji.isNotEmpty)
                                            ? emoji
                                            : '🍽️',
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            itemName,
                                            style: PsgText.label(
                                              14,
                                              color: PsgColors.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '₹${price.toStringAsFixed(price == price.toInt() ? 0 : 2)}',
                                            style: PsgText.body(
                                              12,
                                              color: PsgColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isVeg
                                                ? Colors.green
                                                : Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isVeg ? 'Veg' : 'Non-Veg',
                                          style: PsgText.body(
                                            11,
                                            color: PsgColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _qtyBtn(
                                      icon: Icons.remove,
                                      onTap: () {
                                        if (qty <= 1) return;
                                        setState(() =>
                                            _quantities[doc.id] = qty - 1);
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Text(
                                        '$qty',
                                        style: PsgText.label(
                                          14,
                                          color: PsgColors.onSurface,
                                        ),
                                      ),
                                    ),
                                    _qtyBtn(
                                      icon: Icons.add,
                                      onTap: () {
                                        if (qty >= maxQty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Maximum quantity is $maxQty.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        setState(() =>
                                            _quantities[doc.id] = qty + 1);
                                      },
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      height: 38,
                                      child: FilledButton(
                                        onPressed: controller.isSubmitting
                                            ? null
                                            : () => _bookItem(controller, doc),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: PsgColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                        ),
                                        child: controller.isSubmitting
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                'Book',
                                                style: PsgText.label(
                                                  11,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _qtyBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: PsgColors.primary),
      ),
    );
  }
}
