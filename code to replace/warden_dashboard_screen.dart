// ─────────────────────────────────────────────────────────────────────────────
// Warden Dashboard  —  Glassmorphism UI
// ─────────────────────────────────────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../app/app_routes.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../../../../core/design/psg_design_system.dart';

class WardenDashboardScreen extends StatefulWidget {
  const WardenDashboardScreen({super.key});

  @override
  State<WardenDashboardScreen> createState() => _WardenDashboardScreenState();
}

class _WardenDashboardScreenState extends State<WardenDashboardScreen>
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

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          scrollOffset: _scrollOffset,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded,
                  color: PsgColors.primary, size: 22),
              onPressed: () async {
                await AuthProviderController.of(context).signOut();
                if (mounted) context.go(AppRoutes.login);
              },
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: _buildBody(),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 88,
        bottom: 130, left: 24, right: 24,
      ),
      children: [
        // ── Headline
        StaggeredEntry(
          index: 0,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Operations Command',
                style: PsgText.headline(30, color: PsgColors.primary)),
            const SizedBox(height: 4),
            Text('Manage student requests and facility updates.',
                style: PsgText.body(14,
                    weight: FontWeight.w500,
                    color: PsgColors.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(height: 24),

        // ── Summary metric cards
        StaggeredEntry(
          index: 1,
          child: _summaryRow(),
        ),
        const SizedBox(height: 28),

        // ── Recent Leave Requests
        StaggeredEntry(
          index: 2,
          child: PsgSectionHeader(
            title: 'Recent Leave Requests',
            action: 'View All',
            onAction: () => context.go(AppRoutes.wardenLeaveRequests),
          ),
        ),
        const SizedBox(height: 14),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('leave_requests')
              .where('status', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true)
              .limit(6)
              .snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator()));
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return GlassCard(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 48, color: PsgColors.green.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text('All caught up!',
                        style: PsgText.headline(16,
                            color: PsgColors.onSurfaceVariant,
                            weight: FontWeight.w700)),
                    Text('No pending leave requests.',
                        style: PsgText.body(13,
                            color: PsgColors.onSurfaceVariant)),
                  ],
                ),
              );
            }
            return Column(
              children: List.generate(docs.length, (i) {
                final d = docs[i].data() as Map<String, dynamic>;
                return StaggeredEntry(
                  index: i + 3,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _leaveCard(docs[i].id, d),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  // ── Summary row ──────────────────────────────────────────────────────────
  Widget _summaryRow() {
    return Row(children: [
      Expanded(child: _metricCard(
        'Pending Leaves',
        Icons.departure_board_rounded,
        stream: FirebaseFirestore.instance
            .collection('leave_requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        tagLabel: 'Action Required',
        tagColor: PsgColors.error,
        tagBg: const Color(0xFFFFDAD6),
      )),
      const SizedBox(width: 10),
      Expanded(child: _metricCard(
        'Mess Requests',
        Icons.restaurant_rounded,
        stream: FirebaseFirestore.instance
            .collection('mess_applications')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        tagLabel: 'Menu Changes',
        tagColor: PsgColors.secondary,
        tagBg: const Color(0xFFE0EEFF),
        iconColor: PsgColors.secondary,
      )),
      const SizedBox(width: 10),
      Expanded(child: _metricCard(
        'Open Complaints',
        Icons.report_rounded,
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .where('status',
                whereIn: ['pending', 'in_progress']).snapshots(),
        tagLabel: 'High Priority',
        tagColor: Colors.white,
        tagBg: PsgColors.error,
        iconColor: PsgColors.error,
      )),
    ]);
  }

  Widget _metricCard(
    String label,
    IconData icon, {
    required Stream<QuerySnapshot> stream,
    required String tagLabel,
    required Color tagColor,
    required Color tagBg,
    Color? iconColor,
  }) {
    final effectiveIconColor = iconColor ?? PsgColors.primary;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label,
                  style: PsgText.label(9,
                      letterSpacing: 1.2,
                      color: PsgColors.secondary)),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: effectiveIconColor.withOpacity(0.08),
                  shape: BoxShape.circle),
              child:
                  Icon(icon, color: effectiveIconColor, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (_, s) => Text(
            s.hasData ? '${s.data!.docs.length}' : '–',
            style: PsgText.headline(32, color: PsgColors.primary),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: tagBg,
              borderRadius: BorderRadius.circular(999)),
          child: Text(tagLabel,
              style: PsgText.label(8,
                  letterSpacing: 0.5, color: tagColor)),
        ),
      ]),
    );
  }

  // ── Leave request card ────────────────────────────────────────────────────
  Widget _leaveCard(String id, Map<String, dynamic> d) {
    final fromTs = d['fromDate'] as Timestamp?;
    final toTs = d['toDate'] as Timestamp?;
    final from = fromTs != null
        ? DateFormat('dd MMM').format(fromTs.toDate())
        : '–';
    final to =
        toTs != null ? DateFormat('dd MMM').format(toTs.toDate()) : '–';
    final days = (fromTs != null && toTs != null)
        ? toTs.toDate().difference(fromTs.toDate()).inDays + 1
        : 0;
    final reason = d['reason'] as String? ?? d['leaveType'] as String? ?? 'Leave';
    final description =
        d['description'] as String? ?? d['leaveDescription'] as String? ?? '';
    final userName = d['userName'] as String? ?? 'Student';
    final roomId = d['roomId'] as String? ?? '';

    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          PsgAvatarInitials(name: userName, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(userName,
                  style: PsgText.headline(15,
                      weight: FontWeight.w800,
                      color: PsgColors.primary)),
              Text(roomId.isNotEmpty ? 'Room $roomId' : reason,
                  style: PsgText.body(12,
                      color: PsgColors.onSurfaceVariant,
                      weight: FontWeight.w500)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          const Icon(Icons.calendar_today_rounded,
              size: 13, color: PsgColors.secondary),
          const SizedBox(width: 6),
          Text('$from – $to  ($days day${days == 1 ? '' : 's'})',
              style: PsgText.label(12,
                  color: PsgColors.secondary, letterSpacing: 0.2)),
        ]),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('"$description"',
              style: PsgText.body(12,
                  color: PsgColors.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          _actionBtn(
            label: 'Reject',
            onTap: () => _updateLeave(id, 'rejected'),
            isOutlined: true,
          ),
          const SizedBox(width: 10),
          _actionBtn(
            label: 'Approve',
            onTap: () => _updateLeave(id, 'approved'),
            isOutlined: false,
          ),
        ]),
      ]),
    );
  }

  Widget _actionBtn({
    required String label,
    required VoidCallback onTap,
    required bool isOutlined,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isOutlined
              ? null
              : const LinearGradient(
                  colors: [PsgColors.primary, PsgColors.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isOutlined ? null : null,
          borderRadius: BorderRadius.circular(999),
          border: isOutlined
              ? Border.all(color: PsgColors.error.withOpacity(0.3))
              : null,
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                    color: PsgColors.primaryContainer.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Text(label,
            style: PsgText.label(13,
                color: isOutlined ? PsgColors.error : Colors.white)),
      ),
    );
  }

  Future<void> _updateLeave(String id, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('leave_requests')
          .doc(id)
          .update({'status': status});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave ${status == 'approved' ? 'approved' : 'rejected'}.'),
            backgroundColor: status == 'approved'
                ? PsgColors.green
                : PsgColors.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update leave.')));
      }
    }
  }

  // ── Bottom Nav ───────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return PsgBottomNav(
      currentIndex: _navIndex,
      onTap: (i) {
        setState(() => _navIndex = i);
        final routes = [
          AppRoutes.wardenHome,
          AppRoutes.wardenLeaveRequests,
          AppRoutes.wardenMessApplications,
          AppRoutes.wardenComplaints,
          AppRoutes.wardenNotices,
        ];
        if (i != 0) context.go(routes[i]);
      },
      items: const [
        PsgNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'HOME'),
        PsgNavItem(
            icon: Icons.event_note_outlined,
            activeIcon: Icons.event_note_rounded,
            label: 'LEAVES'),
        PsgNavItem(
            icon: Icons.restaurant_outlined,
            activeIcon: Icons.restaurant_rounded,
            label: 'MESS'),
        PsgNavItem(
            icon: Icons.report_outlined,
            activeIcon: Icons.report_rounded,
            label: 'ISSUES'),
        PsgNavItem(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications_rounded,
            label: 'NOTICES'),
      ],
    );
  }
}
