import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:hostel_app/app/app_routes.dart';
import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';
import 'package:hostel_app/features/tokens/domain/entities/food_token_model.dart';
import 'package:hostel_app/core/design/psg_design_system.dart';
import 'package:hostel_app/services/mock/mock_service.dart';

class BookTokenScreen extends StatefulWidget {
  const BookTokenScreen({super.key});

  @override
  State<BookTokenScreen> createState() => _BookTokenScreenState();
}

class _BookTokenScreenState extends State<BookTokenScreen> {
  final _scrollController = ScrollController();
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  String _meal = 'Lunch';
  final Map<String, int> _itemQty = {};
  bool _loading = false;
  double _scrollOffset = 0;
  late Future<List<Map<String, dynamic>>> _menuFuture;
  late Future<List<FoodTokenModel>> _tokensFuture;

  void _onBottomNavTap(int index) {
    final routeByIndex = {
      0: AppRoutes.studentHome,
      1: AppRoutes.studentTokens,
      2: AppRoutes.studentFees,
      3: AppRoutes.studentNotices,
      4: AppRoutes.studentLeave,
    };
    final route = routeByIndex[index];
    if (route != null) {
      context.go(route);
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(
      () => setState(() => _scrollOffset = _scrollController.offset),
    );
    _menuFuture = MockService.getMenuForSlot(_meal);
    _tokensFuture = _loadMyTokens();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<FoodTokenModel>> _loadMyTokens() async {
    final uid = AuthProviderController.of(context).user?.uid;
    if (uid == null) return const <FoodTokenModel>[];
    return MockService.watchMyTokens(uid).first;
  }

  Future<void> _book(String itemName, double price) async {
    final selectedDay = DateUtils.dateOnly(_date);
    final today = DateUtils.dateOnly(DateTime.now());
    if (selectedDay.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking for previous dates is not allowed.'),
        ),
      );
      return;
    }

    final uid = AuthProviderController.of(context).user?.uid;
    if (uid == null) return;
    final qty = (_itemQty[itemName] ?? 1).clamp(1, 99);
    setState(() => _loading = true);
    await MockService.bookToken(
      FoodTokenModel(
        userId: uid,
        itemName: itemName,
        itemPrice: price,
        quantity: qty,
        totalPrice: price * qty,
        mealSlot: _meal,
        scheduledDate: _date,
        status: FoodTokenStatus.active,
      ),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _tokensFuture = _loadMyTokens();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Token booked')));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
      helpText: 'Select token date',
    );
    if (picked == null) return;
    setState(() => _date = DateUtils.dateOnly(picked));
  }

  int _parseMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return -1;
    final h = int.tryParse(parts[0]) ?? -1;
    final m = int.tryParse(parts[1]) ?? -1;
    if (h < 0 || h > 23 || m < 0 || m > 59) return -1;
    return h * 60 + m;
  }

  bool _isPastCutoff(Map<String, dynamic> item) {
    final cutoff = (item['bookingCutoffTime'] ?? '').toString();
    if (cutoff.isEmpty) return false;
    final cutoffMins = _parseMinutes(cutoff);
    if (cutoffMins < 0) return false;

    final now = DateTime.now();
    final selectedDay = DateUtils.dateOnly(_date);
    final today = DateUtils.dateOnly(now);
    if (selectedDay.isAfter(today)) return false;

    final nowMins = now.hour * 60 + now.minute;
    return nowMins > cutoffMins;
  }

  String _availabilityLine(Map<String, dynamic> item) {
    final from = (item['availableFrom'] ?? '--').toString();
    final to = (item['availableTo'] ?? '--').toString();
    final duration = (item['durationMinutes'] as num?)?.toInt();
    if (duration == null) return '$from - $to';
    return '$from - $to  ($duration mins)';
  }

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          scrollOffset: _scrollOffset,
          title: 'Mess Tokens',
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
              onPressed: () => context.go(AppRoutes.studentMyTokens),
              tooltip: 'My Tokens',
            ),
          ],
        ),
        body: ListView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 88,
            bottom: 130,
            left: 20,
            right: 20,
          ),
          children: [
            Text(
              'Book Extra Food Tokens',
              style: PsgText.headline(28, color: PsgColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              'Select date, slot and quantity based on admin limits.',
              style: PsgText.body(13, color: PsgColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Token Date',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                          ),
                          const Icon(Icons.expand_more_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _meal,
                    items: const ['Breakfast', 'Lunch', 'Dinner']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _meal = value;
                        _menuFuture = MockService.getMenuForSlot(_meal);
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Meal Slot'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _menuFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text('Failed to load menu');
                }
                final items = snapshot.data ?? const <Map<String, dynamic>>[];
                if (items.isEmpty) return const Text('No data available');
                return Column(
                  children: items
                      .map((item) {
                        final name = item['itemName']?.toString() ?? 'Item';
                        final price = (item['price'] as num?)?.toDouble() ?? 0;
                        final maxQty = ((item['maxQty'] as num?)?.toInt() ?? 1)
                            .clamp(1, 99);
                        final qty = (_itemQty[name] ?? 1).clamp(1, maxQty);
                        final disabledByDate = DateUtils.dateOnly(
                          _date,
                        ).isBefore(DateUtils.dateOnly(DateTime.now()));
                        final disabledByCutoff = _isPastCutoff(item);
                        final canBook =
                            !disabledByDate && !disabledByCutoff && !_loading;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            borderRadius: 14,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: PsgText.label(
                                          14,
                                          color: PsgColors.onSurface,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '₹${price.toStringAsFixed(0)}',
                                      style: PsgText.label(
                                        13,
                                        color: PsgColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('Max quantity: $maxQty'),
                                Text(
                                  'Available: ${_availabilityLine(item)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  'Booking cutoff: ${(item['bookingCutoffTime'] ?? '--').toString()}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (disabledByDate)
                                  const Text(
                                    'Past date booking is not allowed.',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                if (disabledByCutoff)
                                  const Text(
                                    'Booking window closed for today.',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      onPressed: qty > 1
                                          ? () => setState(
                                              () => _itemQty[name] = qty - 1,
                                            )
                                          : null,
                                    ),
                                    Text('$qty'),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      onPressed: qty < maxQty
                                          ? () => setState(
                                              () => _itemQty[name] = qty + 1,
                                            )
                                          : null,
                                    ),
                                    const Spacer(),
                                    FilledButton(
                                      onPressed: canBook
                                          ? () => _book(name, price)
                                          : null,
                                      child: const Text('Book'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Upcoming Tokens',
              style: PsgText.headline(18, color: PsgColors.primary),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<FoodTokenModel>>(
              future: _tokensFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text('Failed to load tokens');
                }
                final tokens = snapshot.data ?? const <FoodTokenModel>[];
                if (tokens.isEmpty) {
                  return const Text('No data available');
                }
                return Column(
                  children: tokens
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            borderRadius: 14,
                            child: ListTile(
                              title: Text(t.itemName ?? 'Meal Token'),
                              subtitle: Text(
                                '${t.mealSlot ?? ''} • qty ${t.quantity ?? 1}',
                              ),
                              trailing: Text(t.status.value),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: PsgBottomNav(
          currentIndex: 1,
          onTap: _onBottomNavTap,
          scrollOffset: _scrollOffset,
          items: const [
            PsgNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'HOME',
            ),
            PsgNavItem(
              icon: Icons.restaurant_outlined,
              activeIcon: Icons.restaurant_rounded,
              label: 'MESS',
            ),
            PsgNavItem(
              icon: Icons.payments_outlined,
              activeIcon: Icons.payments_rounded,
              label: 'FEES',
            ),
            PsgNavItem(
              icon: Icons.notifications_outlined,
              activeIcon: Icons.notifications_rounded,
              label: 'NOTICES',
            ),
            PsgNavItem(
              icon: Icons.flight_takeoff_outlined,
              activeIcon: Icons.flight_takeoff_rounded,
              label: 'LEAVE',
            ),
          ],
        ),
      ),
    );
  }
}
