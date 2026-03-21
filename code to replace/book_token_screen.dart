// ─────────────────────────────────────────────────────────────────────────────
// Food Token Screen  —  Glassmorphism UI
// Date carousel  |  Meal toggle  |  Book CTA  |  Upcoming tokens list
// ─────────────────────────────────────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../app/app_routes.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../../../../core/design/psg_design_system.dart';

class BookTokenScreen extends StatefulWidget {
  const BookTokenScreen({super.key});

  @override
  State<BookTokenScreen> createState() => _BookTokenScreenState();
}

class _BookTokenScreenState extends State<BookTokenScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  double _scrollOffset = 0;

  // State
  int _selectedDateOffset = 0; // 0 = today
  int _selectedMeal = 1;       // 0=Breakfast, 1=Lunch, 2=Dinner
  bool _booking = false;

  static const _meals = [
    _Meal('Breakfast', Icons.coffee_rounded, '₹25'),
    _Meal('Lunch', Icons.lunch_dining_rounded, '₹45'),
    _Meal('Dinner', Icons.dinner_dining_rounded, '₹40'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(
        () => setState(() => _scrollOffset = _scrollController.offset));
    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _entryController, curve: Curves.easeOutCubic));
    _entryController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // ── Book token ────────────────────────────────────────────────────────────
  Future<void> _bookToken() async {
    final uid = AuthProviderController.of(context).user?.uid;
    if (uid == null) return;

    final date = DateTime.now().add(Duration(days: _selectedDateOffset));
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final meal = _meals[_selectedMeal].label;

    // Check for existing token
    final existing = await FirebaseFirestore.instance
        .collection('food_tokens')
        .where('userId', isEqualTo: uid)
        .where('date', isEqualTo: dateStr)
        .where('meal', isEqualTo: meal)
        .get();

    if (existing.docs.isNotEmpty && mounted) {
      _snack('Token already booked for this date & meal.');
      return;
    }

    setState(() => _booking = true);
    try {
      await FirebaseFirestore.instance.collection('food_tokens').add({
        'userId': uid,
        'date': dateStr,
        'meal': meal,
        'price': _meals[_selectedMeal].price,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) _snack('Token booked!', isSuccess: true);
    } catch (_) {
      if (mounted) _snack('Booking failed. Try again.');
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  void _snack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor:
            isSuccess ? PsgColors.green : PsgColors.error));
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final uid = AuthProviderController.of(context).user?.uid ?? '';
    final selectedDate =
        DateTime.now().add(Duration(days: _selectedDateOffset));

    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          scrollOffset: _scrollOffset,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: PsgColors.primary, size: 20),
            onPressed: () => context.go(AppRoutes.studentHome),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 88,
                bottom: 60, left: 24, right: 24,
              ),
              children: [
                // ── Header
                StaggeredEntry(
                  index: 0,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Mess Tokens',
                        style: PsgText.headline(30,
                            color: PsgColors.primary)),
                    const SizedBox(height: 4),
                    Text('Book your meal tokens in advance.',
                        style: PsgText.body(14,
                            color: PsgColors.onSurfaceVariant,
                            weight: FontWeight.w500)),
                  ]),
                ),
                const SizedBox(height: 24),

                // ── Date carousel
                StaggeredEntry(
                  index: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SELECT DATE',
                          style: PsgText.label(9,
                              letterSpacing: 1.4,
                              color: PsgColors.onSurfaceVariant
                                  .withOpacity(0.7))),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 7,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final d = DateTime.now()
                                .add(Duration(days: i));
                            final active = i == _selectedDateOffset;
                            return GestureDetector(
                              onTap: () => setState(
                                  () => _selectedDateOffset = i),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                width: 72,
                                decoration: BoxDecoration(
                                  gradient: active
                                      ? const LinearGradient(
                                          colors: [
                                            PsgColors.primary,
                                            PsgColors.primaryContainer
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: active
                                      ? null
                                      : Colors.white.withOpacity(0.40),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                      color: active
                                          ? Colors.transparent
                                          : Colors.white
                                              .withOpacity(0.20)),
                                  boxShadow: active
                                      ? [
                                          BoxShadow(
                                            color: PsgColors
                                                .primaryContainer
                                                .withOpacity(0.35),
                                            blurRadius: 14,
                                            offset:
                                                const Offset(0, 4),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('E').format(d).toUpperCase(),
                                      style: PsgText.label(10,
                                          letterSpacing: 0.8,
                                          color: active
                                              ? Colors.white
                                                  .withOpacity(0.80)
                                              : PsgColors
                                                  .onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${d.day}',
                                      style: PsgText.headline(26,
                                          color: active
                                              ? Colors.white
                                              : PsgColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Meal selector
                StaggeredEntry(
                  index: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MEAL TYPE',
                          style: PsgText.label(9,
                              letterSpacing: 1.4,
                              color: PsgColors.onSurfaceVariant
                                  .withOpacity(0.7))),
                      const SizedBox(height: 12),
                      GlassCard(
                        borderRadius: 20,
                        padding:
                            const EdgeInsets.all(6),
                        child: Row(
                          children: List.generate(3, (i) {
                            final active = i == _selectedMeal;
                            final m = _meals[i];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedMeal = i),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? PsgColors.primaryContainer
                                        : Colors.transparent,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    boxShadow: active
                                        ? [
                                            BoxShadow(
                                              color: PsgColors
                                                  .primaryContainer
                                                  .withOpacity(0.25),
                                              blurRadius: 10,
                                              offset:
                                                  const Offset(0, 3),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(m.icon,
                                          color: active
                                              ? Colors.white
                                              : PsgColors.primary,
                                          size: 22),
                                      const SizedBox(height: 4),
                                      Text(m.label,
                                          style: PsgText.label(9,
                                              letterSpacing: 0.6,
                                              color: active
                                                  ? Colors.white
                                                  : PsgColors
                                                      .onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Booking summary + CTA
                StaggeredEntry(
                  index: 3,
                  child: GlassCard(
                    child: Column(children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                            Text(
                                '${_meals[_selectedMeal].label} Token',
                                style: PsgText.headline(16,
                                    weight: FontWeight.w800,
                                    color: PsgColors.primary)),
                            const SizedBox(height: 2),
                            Text(
                                DateFormat('EEEE, dd MMM')
                                    .format(selectedDate),
                                style: PsgText.body(12,
                                    color: PsgColors.onSurfaceVariant,
                                    weight: FontWeight.w500)),
                          ]),
                          Text(_meals[_selectedMeal].price,
                              style: PsgText.headline(30,
                                  color: PsgColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      PsgFilledButton(
                        label: 'Book Token Now',
                        icon: Icons.confirmation_number_rounded,
                        loading: _booking,
                        onPressed: _bookToken,
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Upcoming tokens
                StaggeredEntry(
                  index: 4,
                  child: PsgSectionHeader(
                      title: 'Upcoming Tokens',
                      action: 'History',
                      onAction: () => context.go(AppRoutes.studentMyTokens)),
                ),
                const SizedBox(height: 14),

                if (uid.isNotEmpty)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('food_tokens')
                        .where('userId', isEqualTo: uid)
                        .where('status', isEqualTo: 'active')
                        .orderBy('createdAt', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (!snap.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final docs = snap.data!.docs;
                      if (docs.isEmpty) {
                        return Center(
                            child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('No active tokens.',
                              style: PsgText.body(14,
                                  color: PsgColors.onSurfaceVariant)),
                        ));
                      }
                      return Column(
                        children: List.generate(docs.length, (i) {
                          final d =
                              docs[i].data() as Map<String, dynamic>;
                          final meal = d['meal'] as String? ?? '';
                          final date = d['date'] as String? ?? '';
                          final status =
                              d['status'] as String? ?? 'active';
                          return StaggeredEntry(
                            index: i + 5,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GlassCard(
                                borderRadius: 16,
                                padding: const EdgeInsets.all(14),
                                child: Row(children: [
                                  Container(
                                    width: 56, height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCEE5FF),
                                      borderRadius:
                                          BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                        Icons.qr_code_2_rounded,
                                        color: PsgColors.primary,
                                        size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(meal,
                                          style: PsgText.label(14,
                                              color: PsgColors.primary)),
                                      const SizedBox(height: 2),
                                      Text(date,
                                          style: PsgText.body(11,
                                              color: PsgColors
                                                  .onSurfaceVariant,
                                              weight: FontWeight.w500)),
                                    ]),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: PsgColors.primary
                                          .withOpacity(0.08),
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                        status.toUpperCase(),
                                        style: PsgText.label(9,
                                            letterSpacing: 0.6,
                                            color: PsgColors.primary)),
                                  ),
                                ]),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Meal {
  final String label;
  final IconData icon;
  final String price;
  const _Meal(this.label, this.icon, this.price);
}
