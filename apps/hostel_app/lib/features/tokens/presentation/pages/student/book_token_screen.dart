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

class _BookTokenScreenState extends State<BookTokenScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  late TabController _tabController;
  final Map<String, int> _quantities = {};

  static const _meals = ['Breakfast', 'Lunch', 'Dinner'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _meals.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _menuStream() {
    return FirebaseFirestore.instance
        .collection('food_token_items')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  DateTime get _selectedDayStart =>
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

  DateTime get _selectedDayEnd =>
      _selectedDayStart.add(const Duration(days: 1));

  String _normalizeKey(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  String _resolveMealSlot(Map<String, dynamic> data) {
    final fromMealSlot = data['mealSlot'] as String?;
    if (fromMealSlot != null && fromMealSlot.trim().isNotEmpty) {
      return fromMealSlot;
    }
    final fromLegacySlot = data['slot'] as String?;
    if (fromLegacySlot != null && fromLegacySlot.trim().isNotEmpty) {
      return fromLegacySlot;
    }
    // Keep compatibility with legacy docs that were displayed as Lunch in admin.
    return 'Lunch';
  }

  String _resolveItemName(Map<String, dynamic> data) {
    return (data['name'] as String?) ??
        (data['itemName'] as String?) ??
        'Menu Item';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _selectedMonthMessApprovals(
    String userId,
  ) {
    return FirebaseFirestore.instance
        .collection('mess_applications')
        .where('studentId', isEqualTo: userId)
        .snapshots();
  }

  bool _isFinalApproval(Map<String, dynamic> data) {
    final status = (data['status'] as String? ?? '').toLowerCase();
    if (status != 'approved') {
      return false;
    }

    final wardenDecision = (data['wardenDecision'] as String?)?.toLowerCase();
    final adminDecision = (data['adminDecision'] as String?)?.toLowerCase();

    final wardenOk = wardenDecision == null || wardenDecision == 'approved';
    final adminOk = adminDecision == null || adminDecision == 'approved';
    return wardenOk && adminOk;
  }

  bool _isApprovedForSelectedDate(Map<String, dynamic> data) {
    final requestedMess =
        (data['requestedMess'] as String? ?? '').trim().toLowerCase();
    if (!requestedMess.contains('north')) {
      return false;
    }

    if (!_isFinalApproval(data)) {
      return false;
    }

    final start = (data['periodStart'] as Timestamp?)?.toDate();
    final end = (data['periodEnd'] as Timestamp?)?.toDate();

    if (start != null && end != null) {
      final selected = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(end.year, end.month, end.day);
      return !selected.isBefore(startDay) && !selected.isAfter(endDay);
    }

    final year = (data['targetYear'] as num?)?.toInt();
    final month = (data['targetMonth'] as num?)?.toInt();
    if (year != null && month != null) {
      return year == _selectedDate.year && month == _selectedDate.month;
    }

    return false;
  }

  bool _isNorthIndianForSelectedDate(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> approvals,
  ) {
    return approvals.any((doc) {
      final data = doc.data();
      return _isApprovedForSelectedDate(data);
    });
  }

  String _resolveAudience(Map<String, dynamic> data) {
    final raw = (data['audience'] as String?) ??
        (data['messCategory'] as String?) ??
        'Both';
    final key = _normalizeKey(raw);
    if (key.contains('north')) return 'north';
    if (key.contains('south') || key.contains('regular')) return 'south';
    return 'both';
  }

  bool _isAudienceVisible(Map<String, dynamic> data, bool isNorthStudent) {
    final audience = _resolveAudience(data);
    if (audience == 'north') {
      return isNorthStudent;
    }
    if (audience == 'south') {
      return !isNorthStudent;
    }
    return true;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _myActiveTokensForSelectedSlot(
    String userId,
    String meal,
  ) {
    return FirebaseFirestore.instance
        .collection('food_tokens')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .where('mealSlot', isEqualTo: meal)
        .where(
          'scheduledDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_selectedDayStart),
        )
        .where('scheduledDate', isLessThan: Timestamp.fromDate(_selectedDayEnd))
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
    int maxQty,
    String meal,
    int qty,
  ) async {
    final uid = AuthProviderController.of(context).user?.uid;
    if (uid == null) return;

    final data = doc.data();
    if (qty <= 0) return;

    final matchingTokens = await FirebaseFirestore.instance
        .collection('food_tokens')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .where('mealSlot', isEqualTo: meal)
        .where(
          'scheduledDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_selectedDayStart),
        )
        .where('scheduledDate', isLessThan: Timestamp.fromDate(_selectedDayEnd))
        .get();

    final selectedItemKey = _normalizeKey(_resolveItemName(data));

    final alreadyBookedQty = matchingTokens.docs.fold<int>(0, (sum, tokenDoc) {
      final token = tokenDoc.data();
      final bookedItemKey = _normalizeKey(token['itemName'] as String?);
      if (bookedItemKey != selectedItemKey) {
        return sum;
      }
      return sum + ((token['quantity'] as num?)?.toInt() ?? 0);
    });

    final remainingAllowed = maxQty - alreadyBookedQty;
    if (remainingAllowed <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You have already booked the maximum allowed quantity ($maxQty) for this item.',
          ),
        ),
      );
      return;
    }

    if (qty > remainingAllowed) {
      if (mounted) {
        setState(() => _quantities[doc.id] = remainingAllowed);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Only $remainingAllowed more can be booked for this item.',
            ),
          ),
        );
      }
      return;
    }

    final success = await controller.bookToken(
      userId: uid,
      itemName: (data['name'] as String?) ??
          (data['itemName'] as String?) ??
          'Unknown Item',
      itemPrice: ((data['price'] as num?) ?? 0).toDouble(),
      quantity: qty,
      mealSlot: meal,
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

  Widget _buildMealPanel(String meal, FoodTokenController controller) {
    final uid = AuthProviderController.of(context).user?.uid;
    if (uid == null) {
      return Center(
        child: Text(
          'Sign in again to continue booking.',
          style: PsgText.body(14, color: PsgColors.error),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _selectedMonthMessApprovals(uid),
      builder: (context, approvalSnap) {
        final approvals = approvalSnap.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final isNorthStudent = _isNorthIndianForSelectedDate(approvals);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _menuStream(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting ||
                approvalSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || approvalSnap.hasError) {
              return Center(
                child: Text(
                  'Failed to load menu items.',
                  style: PsgText.body(14, color: PsgColors.error),
                ),
              );
            }

            final docs = snap.data?.docs ?? [];
            final availableDocs = docs.where((doc) {
              final data = doc.data();
              final stock = ((data['totalQuantity'] as num?) ?? 0).toInt();
              return stock > 0 && _isAudienceVisible(data, isNorthStudent);
            }).toList();

            // Strict segregation: a menu item only appears in its assigned meal tab.
            final mealDocs = availableDocs.where((doc) {
              final slot = _resolveMealSlot(doc.data());
              return _normalizeKey(slot) == _normalizeKey(meal);
            }).toList();

            if (mealDocs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No $meal items available for your mess plan.',
                    style: PsgText.body(14, color: PsgColors.onSurfaceVariant),
                  ),
                ),
              );
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _myActiveTokensForSelectedSlot(uid, meal),
              builder: (context, tokenSnap) {
                final bookedByItem = <String, int>{};
                for (final tokenDoc in tokenSnap.data?.docs ?? const []) {
                  final token = tokenDoc.data();
                  final tokenItemName = token['itemName'] as String?;
                  if (tokenItemName == null || tokenItemName.isEmpty) {
                    continue;
                  }
                  final tokenQty = ((token['quantity'] as num?) ?? 0).toInt();
                  final tokenItemKey = _normalizeKey(tokenItemName);
                  bookedByItem[tokenItemKey] =
                      (bookedByItem[tokenItemKey] ?? 0) + tokenQty;
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: mealDocs.map((doc) {
                    final data = doc.data();
                    final itemName = _resolveItemName(data);
                    final price = ((data['price'] as num?) ?? 0).toDouble();
                    final isVeg = (data['isVeg'] as bool?) ?? true;
                    final stock =
                        ((data['totalQuantity'] as num?) ?? 0).toInt();
                    final maxQty =
                        ((data['limitPerPerson'] as num?) ?? 5).toInt();
                    final alreadyBooked =
                        bookedByItem[_normalizeKey(itemName)] ?? 0;
                    final remainingForStudent =
                        (maxQty - alreadyBooked).clamp(0, maxQty).toInt();
                    final allowedMax = remainingForStudent < stock
                        ? remainingForStudent
                        : stock;
                    final emoji = (data['emoji'] as String?)?.trim();
                    final qtyKey = '${_normalizeKey(meal)}:${doc.id}';
                    final qty = _quantities[qtyKey] ?? 1;

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
                                      const SizedBox(height: 2),
                                      Text(
                                        'Stock: $stock',
                                        style: PsgText.body(
                                          11,
                                          color: stock <= 10
                                              ? PsgColors.error
                                              : PsgColors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Booked by you: $alreadyBooked / $maxQty',
                                        style: PsgText.body(
                                          11,
                                          color: remainingForStudent == 0
                                              ? PsgColors.error
                                              : PsgColors.onSurfaceVariant,
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
                                        color:
                                            isVeg ? Colors.green : Colors.red,
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
                                    setState(
                                        () => _quantities[qtyKey] = qty - 1);
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
                                    if (qty >= allowedMax) {
                                      final maxAllowed = allowedMax;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            maxAllowed > 0
                                                ? 'Maximum additional quantity is $maxAllowed.'
                                                : 'You cannot book more of this item for the selected slot.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    setState(
                                        () => _quantities[qtyKey] = qty + 1);
                                  },
                                ),
                                const Spacer(),
                                SizedBox(
                                  height: 38,
                                  child: FilledButton(
                                    onPressed: controller.isSubmitting ||
                                            allowedMax <= 0
                                        ? null
                                        : () => _bookItem(
                                              controller,
                                              doc,
                                              maxQty,
                                              meal,
                                              qty,
                                            ),
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
                                            child: CircularProgressIndicator(
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthProviderController.of(context).user?.uid;

    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          scrollOffset: 0,
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
            return Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 88,
                bottom: 20,
                left: 16,
                right: 16,
              ),
              child: Column(
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Date',
                          style:
                              PsgText.headline(16, color: PsgColors.onSurface),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
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
                        const SizedBox(height: 10),
                        if (uid != null)
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _selectedMonthMessApprovals(uid),
                            builder: (context, snap) {
                              final approvals = snap.data?.docs ??
                                  <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                              final isNorthStudent =
                                  _isNorthIndianForSelectedDate(approvals);

                              final label = isNorthStudent
                                  ? 'North Indian tokens enabled for selected date'
                                  : 'South/regular tokens enabled for selected date';
                              final bgColor = isNorthStudent
                                  ? Colors.indigo.withValues(alpha: 0.14)
                                  : PsgColors.primary.withValues(alpha: 0.12);
                              final fgColor =
                                  isNorthStudent ? Colors.indigo : PsgColors.primary;

                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: fgColor.withValues(alpha: 0.20),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isNorthStudent
                                          ? Icons.restaurant_menu_rounded
                                          : Icons.restaurant_rounded,
                                      size: 16,
                                      color: fgColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        label,
                                        style: PsgText.body(
                                          11,
                                          color: fgColor,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 12),
                        TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: PsgColors.onSurface,
                          indicator: BoxDecoration(
                            color: PsgColors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          tabs: _meals
                              .map((meal) => Tab(text: meal))
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: _meals
                          .map((meal) => _buildMealPanel(meal, controller))
                          .toList(growable: false),
                    ),
                  ),
                ],
              ),
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
