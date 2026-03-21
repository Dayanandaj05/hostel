// ─────────────────────────────────────────────────────────────────────────────
// Student Dashboard  —  Glassmorphism UI
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../app/app_routes.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../../../student/data/student_profile_provider.dart';
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
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(
        () => setState(() => _scrollOffset = _scrollController.offset));

    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fadeAnim =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _entryController, curve: Curves.easeOutCubic));
    _entryController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = AuthProviderController.of(context).user?.uid;
      if (uid != null) context.read<StudentProfileProvider>().startWatching(uid);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final profile = context.watch<StudentProfileProvider>();

    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          scrollOffset: _scrollOffset,
          actions: [
            _balanceChip(profile.balance),
            const SizedBox(width: 12),
            _avatarButton(),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: _buildBody(profile),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────
  Widget _buildBody(StudentProfileProvider profile) {
    return switch (_navIndex) {
      0 => _homeTab(profile),
      1 => _messTab(profile),
      2 => _feesTab(profile),
      3 => _noticesTab(),
      _ => _homeTab(profile),
    };
  }

  Widget _homeTab(StudentProfileProvider profile) {
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 88,
        bottom: 130,
        left: 24,
        right: 24,
      ),
      children: [
        // ── Greeting
        StaggeredEntry(
          index: 0,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hi, ${profile.displayName.split(' ').first}',
                style: PsgText.headline(32, color: PsgColors.primary)),
            const SizedBox(height: 4),
            Text('Welcome back to your hostel hub.',
                style: PsgText.body(14,
                    weight: FontWeight.w500,
                    color: PsgColors.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(height: 24),

        // ── Profile card
        StaggeredEntry(
          index: 1,
          child: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('CURRENT RESIDENCE',
                        style: PsgText.label(9,
                            letterSpacing: 1.6,
                            color: PsgColors.secondary)),
                    const SizedBox(height: 4),
                    Text(profile.roomId ?? 'Room 402-B',
                        style: PsgText.headline(34, color: PsgColors.primary)),
                  ]),
                  const Icon(Icons.qr_code_2_rounded,
                      color: PsgColors.primary, size: 32),
                ],
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: _infoChip('Roll Number', profile.rollNumber)),
                const SizedBox(width: 12),
                Expanded(child: _infoChip('Mess Wing', profile.messType)),
              ]),
              const SizedBox(height: 20),
              // Swipe dot indicator
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                    width: 24, height: 5,
                    decoration: BoxDecoration(
                        color: PsgColors.primary,
                        borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 5),
                Container(
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3))),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 14),

        // ── Mini stats
        StaggeredEntry(
          index: 2,
          child: Row(children: [
            Expanded(child: _statCard('5', 'Leave Bal', isGreen: false)),
            const SizedBox(width: 10),
            Expanded(child: _statCard('2', 'Tokens', isGreen: false)),
            const SizedBox(width: 10),
            Expanded(child: _statCard('₹0', 'Fees Due', isGreen: true)),
          ]),
        ),
        const SizedBox(height: 28),

        // ── Feature grid
        StaggeredEntry(
          index: 3,
          child: PsgSectionHeader(title: 'Quick Actions', action: 'View All'),
        ),
        const SizedBox(height: 16),
        _featureGrid(),
      ],
    );
  }

  // ── Mess tab ─────────────────────────────────────────────────────────────
  Widget _messTab(StudentProfileProvider profile) {
    return ListView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 88,
        bottom: 130, left: 24, right: 24,
      ),
      children: [
        Text('Mess Details',
            style: PsgText.headline(28, color: PsgColors.primary)),
        const SizedBox(height: 20),
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _messInfoRow('Current Mess', profile.messType),
            const Divider(height: 24),
            _messInfoRow('Supervisor', profile.messSupervisors.firstOrNull ?? 'N/A'),
          ]),
        ),
        const SizedBox(height: 20),
        if (!profile.isNorthIndianMess)
          PsgFilledButton(
            label: 'Apply for North Indian Mess',
            icon: Icons.swap_horiz_rounded,
            onPressed: () => context.go(AppRoutes.studentMessApplication),
          ),
      ],
    );
  }

  Widget _messInfoRow(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: PsgText.body(13,
              color: PsgColors.onSurfaceVariant,
              weight: FontWeight.w500)),
      Text(value,
          style: PsgText.label(14, color: PsgColors.onSurface)),
    ]);
  }

  // ── Fees tab ──────────────────────────────────────────────────────────────
  Widget _feesTab(StudentProfileProvider profile) {
    return ListView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 88,
        bottom: 130, left: 24, right: 24,
      ),
      children: [
        Text('Fee Summary',
            style: PsgText.headline(28, color: PsgColors.primary)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
              child: _feeCard('Establishment',
                  '₹${profile.establishment}', PsgColors.primary)),
          const SizedBox(width: 10),
          Expanded(
              child: _feeCard(
                  'Deposit', '₹${profile.deposit}', const Color(0xFF4F46E5))),
          const SizedBox(width: 10),
          Expanded(
              child: _feeCard('Balance', '₹${profile.balance}',
                  profile.balance > 0
                      ? PsgColors.green
                      : PsgColors.error)),
        ]),
        const SizedBox(height: 24),
        PsgFilledButton(
          label: 'Pay Now',
          icon: Icons.payments_rounded,
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Redirecting to payment portal…'))),
        ),
      ],
    );
  }

  Widget _feeCard(String label, String amount, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      borderRadius: 14,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(amount,
            style: PsgText.headline(16, color: color),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(label,
            style: PsgText.label(9,
                letterSpacing: 0.6,
                color: PsgColors.onSurfaceVariant),
            textAlign: TextAlign.center),
      ]),
    );
  }

  // ── Notices tab ──────────────────────────────────────────────────────────
  Widget _noticesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notices')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No notices yet',
                    style: PsgText.body(15,
                        color: PsgColors.onSurfaceVariant)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 88,
            bottom: 130, left: 24, right: 24,
          ),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final ts = d['createdAt'] as Timestamp?;
            final date = ts != null
                ? DateFormat('dd MMM yyyy').format(ts.toDate())
                : '';
            return StaggeredEntry(
              index: i,
              child: GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: PsgColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.announcement_rounded,
                        color: PsgColors.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(d['title'] ?? '',
                          style: PsgText.label(14,
                              color: PsgColors.onSurface),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(d['body'] ?? '',
                          style: PsgText.body(12,
                              color: PsgColors.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(date,
                          style: PsgText.label(10,
                              letterSpacing: 0.4,
                              color: PsgColors.outline)),
                    ]),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  // ── Feature grid ─────────────────────────────────────────────────────────
  Widget _featureGrid() {
    final modules = [
      _Mod('Leave', Icons.flight_takeoff_rounded,
          AppRoutes.studentLeave, const Color(0xFFEFF6FF), const Color(0xFF003F87)),
      _Mod('Food Token', Icons.confirmation_number_rounded,
          AppRoutes.studentTokens, const Color(0xFFEFFEFE), const Color(0xFF366288)),
      _Mod('T-Shirt', Icons.checkroom_rounded,
          AppRoutes.studentTShirt, const Color(0xFFEEF2FF), const Color(0xFF4F46E5)),
      _Mod('Hostel Day', Icons.celebration_rounded,
          AppRoutes.studentDayEntry, const Color(0xFFFFF7ED), const Color(0xFFEA580C)),
      _Mod('My Room', Icons.meeting_room_rounded,
          AppRoutes.studentRoom, const Color(0xFFEFF6FF), const Color(0xFF003F87)),
      _Mod('Complaints', Icons.report_problem_rounded,
          AppRoutes.studentComplaints, const Color(0xFFFFF1F2), const Color(0xFFBA1A1A)),
      _Mod('Notices', Icons.notifications_active_rounded,
          AppRoutes.studentNotices, const Color(0xFFFAF5FF), const Color(0xFF7C3AED)),
      _Mod('Profile', Icons.person_rounded,
          AppRoutes.studentProfile, const Color(0xFFF8FAFC), const Color(0xFF475569)),
      _Mod('Contact', Icons.support_agent_rounded,
          AppRoutes.studentContact, const Color(0xFFF0FDF4), const Color(0xFF15803D)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.82),
      itemCount: modules.length,
      itemBuilder: (ctx, i) {
        final m = modules[i];
        return StaggeredEntry(
          index: i,
          child: GestureDetector(
            onTap: () => context.go(m.route),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 62, height: 62,
                  decoration: BoxDecoration(
                    color: m.bg,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: m.fg.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Icon(m.icon, color: m.fg, size: 28),
                ),
                const SizedBox(height: 10),
                Text(m.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: PsgText.label(10,
                        letterSpacing: 0.2,
                        color: PsgColors.onSurfaceVariant)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Sub-widgets ──────────────────────────────────────────────────────────
  Widget _balanceChip(int balance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: PsgColors.primary,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
              color: PsgColors.primary.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.account_balance_wallet_rounded,
            color: Colors.white, size: 14),
        const SizedBox(width: 5),
        Text('₹$balance',
            style: PsgText.label(13, color: Colors.white)),
      ]),
    );
  }

  Widget _avatarButton() {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
            colors: [PsgColors.primary, PsgColors.primaryContainer]),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child:
          const Icon(Icons.person_rounded, color: Colors.white, size: 22),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.30),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(),
            style: PsgText.label(8,
                letterSpacing: 1.0,
                color: Colors.grey.shade500)),
        const SizedBox(height: 3),
        Text(value,
            style: PsgText.label(13, color: PsgColors.onSurface)),
      ]),
    );
  }

  Widget _statCard(String value, String label, {required bool isGreen}) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      borderRadius: 14,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value,
            style: PsgText.headline(20,
                color: isGreen ? PsgColors.green : PsgColors.primary)),
        const SizedBox(height: 3),
        Text(label.toUpperCase(),
            style: PsgText.label(8,
                letterSpacing: 0.6,
                color: Colors.grey.shade500),
            textAlign: TextAlign.center),
      ]),
    );
  }

  // ── Bottom Nav ───────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return PsgBottomNav(
      currentIndex: _navIndex,
      onTap: (i) => setState(() {
        _navIndex = i;
        _scrollController.jumpTo(0);
      }),
      items: const [
        PsgNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'HOME'),
        PsgNavItem(
            icon: Icons.restaurant_outlined,
            activeIcon: Icons.restaurant_rounded,
            label: 'MESS'),
        PsgNavItem(
            icon: Icons.payments_outlined,
            activeIcon: Icons.payments_rounded,
            label: 'FEES'),
        PsgNavItem(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications_rounded,
            label: 'NOTICES'),
        PsgNavItem(
            icon: Icons.person_outlined,
            activeIcon: Icons.person_rounded,
            label: 'PROFILE'),
      ],
    );
  }
}

// ── Data class ───────────────────────────────────────────────────────────────
class _Mod {
  final String label;
  final IconData icon;
  final String route;
  final Color bg;
  final Color fg;
  const _Mod(this.label, this.icon, this.route, this.bg, this.fg);
}
