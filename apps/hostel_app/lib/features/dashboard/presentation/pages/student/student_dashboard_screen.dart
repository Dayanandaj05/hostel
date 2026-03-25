// ─────────────────────────────────────────────────────────────────────────────
// Student Dashboard  —  Glassmorphism UI  |  Mock-Offline Compatible
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../app/app_routes.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../../../student/data/student_profile_provider.dart';
import '../../../../tokens/presentation/controllers/food_token_controller.dart';
import '../../../../tokens/domain/entities/food_token_model.dart';
import '../../../../../core/design/psg_design_system.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(
      () => setState(() => _scrollOffset = _scrollController.offset),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );
    _entryController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = AuthProviderController.of(context).user?.uid;
      if (uid != null) {
        context.read<StudentProfileProvider>().startWatching(uid);
        context.read<FoodTokenController>().startWatchingTokens(uid);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<StudentProfileProvider>();
    final tokenController = context.watch<FoodTokenController>();
    final now = DateTime.now();
    final activeBookedTokens = tokenController.myTokens
        .where((t) => t.status == FoodTokenStatus.active)
        .length;
    final monthMessBill = tokenController.myTokens
        .where((t) {
          final d = t.scheduledDate;
          if (d == null) return false;
          return d.year == now.year &&
              d.month == now.month &&
              t.status != FoodTokenStatus.cancelled;
        })
        .fold<double>(0, (sum, t) => sum + (t.totalPrice ?? t.itemPrice ?? 0));

    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          scrollOffset: _scrollOffset,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: PsgColors.primary,
                size: 20,
              ),
              onPressed: () async {
                await AuthProviderController.of(context).signOut();
                if (mounted && context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
              tooltip: 'Logout',
            ),
            const SizedBox(width: 4),
            _balanceChip(profile.balance),
            const SizedBox(width: 12),
            _avatarButton(),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: _homeTab(profile, activeBookedTokens, monthMessBill),
          ),
        ),
      ),
    );
  }

  Widget _homeTab(
    StudentProfileProvider profile,
    int activeBookedTokens,
    double monthMessBill,
  ) {
    return ListView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 88,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      children: [
        // ── Greeting
        StaggeredEntry(
          index: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.go(AppRoutes.studentProfile),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hi, ${profile.displayName.split(' ').first}',
                      style: PsgText.headline(32, color: PsgColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: PsgColors.primary.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap your name to open profile.',
                style: PsgText.body(
                  14,
                  weight: FontWeight.w500,
                  color: PsgColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Profile card
        StaggeredEntry(
          index: 1,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRENT RESIDENCE',
                          style: PsgText.label(
                            9,
                            letterSpacing: 1.6,
                            color: PsgColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.roomId,
                          style: PsgText.headline(34, color: PsgColors.primary),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.qr_code_2_rounded,
                      color: PsgColors.primary,
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _infoChip('Roll Number', profile.rollNumber),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _infoChip('Mess Wing', profile.messType)),
                  ],
                ),
                const SizedBox(height: 20),
                // Swipe dot indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 5,
                      decoration: BoxDecoration(
                        color: PsgColors.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Mini stats
        StaggeredEntry(
          index: 2,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go(AppRoutes.studentMyTokens),
                  child: _statCard(
                    '$activeBookedTokens',
                    'Booked Tokens',
                    isGreen: false,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _statCard('3', 'Tokens', isGreen: false)),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  '₹${monthMessBill.toStringAsFixed(0)}',
                  'Mess Bill (Month)',
                  isGreen: true,
                ),
              ),
            ],
          ),
        ),

        // ── Feature grid
        _featureGrid(),
      ],
    );
  }

  Widget _featureGrid() {
    final modules = [
      _Mod(
        'T-Shirt',
        Icons.checkroom_rounded,
        AppRoutes.studentTShirt,
        const Color(0xFF4F46E5),
      ),
      _Mod(
        'Hostel Day',
        Icons.celebration_rounded,
        AppRoutes.studentDayEntry,
        const Color(0xFFEA580C),
      ),
      _Mod(
        'My Room',
        Icons.meeting_room_rounded,
        AppRoutes.studentRoom,
        const Color(0xFF003F87),
      ),
      _Mod(
        'Complaints',
        Icons.report_problem_rounded,
        AppRoutes.studentComplaints,
        const Color(0xFFBA1A1A),
      ),
      _Mod(
        'Contact',
        Icons.support_agent_rounded,
        AppRoutes.studentContact,
        const Color(0xFF15803D),
      ),
    ];

    return Column(
      children: modules
          .asMap()
          .entries
          .map((entry) {
            final i = entry.key;
            final m = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: i == modules.length - 1 ? 0 : 10,
              ),
              child: StaggeredEntry(
                index: i + 4,
                child: GlassCard(
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  onTap: () => context.go(m.route),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: m.fg.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(m.icon, color: m.fg, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          m.label,
                          style: PsgText.label(14, color: PsgColors.onSurface),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: PsgColors.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _balanceChip(int balance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: PsgColors.primary,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: PsgColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text('₹$balance', style: PsgText.label(13, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _avatarButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [PsgColors.primary, PsgColors.primaryContainer],
        ),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: PsgText.label(
              8,
              letterSpacing: 1.0,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 3),
          Text(value, style: PsgText.label(13, color: PsgColors.onSurface)),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, {required bool isGreen}) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      borderRadius: 14,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: PsgText.headline(
              20,
              color: isGreen ? PsgColors.green : PsgColors.primary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: PsgText.label(
              8,
              letterSpacing: 0.6,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Mod {
  final String label;
  final IconData icon;
  final String route;
  final Color fg;
  const _Mod(this.label, this.icon, this.route, this.fg);
}
