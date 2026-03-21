// ─────────────────────────────────────────────────────────────────────────────
// Admin Dashboard  —  Glassmorphism UI
// ─────────────────────────────────────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/app_routes.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../../../../core/design/psg_design_system.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
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

  static const _actions = [
    _Action('Add Users', Icons.person_add_rounded, AppRoutes.adminUsers),
    _Action('Assign Roles', Icons.admin_panel_settings_rounded, AppRoutes.adminRoles),
    _Action('Allocate Rooms', Icons.meeting_room_rounded, AppRoutes.adminRooms),
    _Action('Statistics', Icons.analytics_rounded, AppRoutes.adminDashboard),
    _Action('Notices', Icons.campaign_rounded, AppRoutes.adminNotices),
    _Action('Hostel Day', Icons.celebration_rounded, AppRoutes.adminHostelDay),
  ];

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
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 88,
                bottom: 60, left: 24, right: 24,
              ),
              children: [
                // ── Headline
                StaggeredEntry(
                  index: 0,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('System Overview',
                        style: PsgText.headline(30,
                            color: PsgColors.primary)),
                    const SizedBox(height: 4),
                    Text(
                        'Welcome back, Administrator. '
                        'Here\'s the current pulse of PSG Hostel.',
                        style: PsgText.body(14,
                            color: PsgColors.onSurfaceVariant,
                            weight: FontWeight.w500)),
                  ]),
                ),
                const SizedBox(height: 24),

                // ── Metrics bento
                StaggeredEntry(index: 1, child: _metricsGrid()),
                const SizedBox(height: 28),

                // ── Admin actions
                StaggeredEntry(
                  index: 2,
                  child: PsgSectionHeader(
                      title: 'Administrative Actions',
                      action: 'View Logs'),
                ),
                const SizedBox(height: 16),
                StaggeredEntry(index: 3, child: _actionsGrid()),
                const SizedBox(height: 28),

                // ── Recent activity
                StaggeredEntry(
                    index: 4,
                    child: PsgSectionHeader(
                        title: 'Recent System Activity')),
                const SizedBox(height: 14),
                StaggeredEntry(index: 5, child: _activityCard()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Metrics 2×2 ──────────────────────────────────────────────────────────
  Widget _metricsGrid() {
    final metrics = [
      _Metric('Total Students', Icons.group_rounded,
          FirebaseFirestore.instance.collection('users').snapshots(),
          const Color(0xFF003F87)),
      _Metric('Total Rooms', Icons.bed_rounded,
          FirebaseFirestore.instance.collection('rooms').snapshots(),
          const Color(0xFF4F46E5)),
      _Metric(
          'Pending Leaves',
          Icons.event_busy_rounded,
          FirebaseFirestore.instance
              .collection('leave_requests')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          PsgColors.error),
      _Metric(
          'Open Complaints',
          Icons.report_problem_rounded,
          FirebaseFirestore.instance.collection('complaints').where(
              'status',
              whereIn: ['pending', 'in_progress']).snapshots(),
          const Color(0xFFB45309)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4),
      itemCount: metrics.length,
      itemBuilder: (_, i) {
        final m = metrics[i];
        return GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(m.label,
                        style: PsgText.label(9,
                            letterSpacing: 1.2,
                            color: PsgColors.secondary)),
                  ),
                  Icon(m.icon, color: m.color.withOpacity(0.3), size: 28),
                ],
              ),
              const Spacer(),
              StreamBuilder<QuerySnapshot>(
                stream: m.stream,
                builder: (_, s) => Text(
                  s.hasData ? '${s.data!.docs.length}' : '–',
                  style: PsgText.headline(36, color: m.color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Actions grid ──────────────────────────────────────────────────────────
  Widget _actionsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85),
      itemCount: _actions.length,
      itemBuilder: (_, i) {
        final a = _actions[i];
        return StaggeredEntry(
          index: i,
          child: GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(0),
            onTap: () => context.go(a.route),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: PsgColors.primary.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(a.icon,
                      color: PsgColors.primary, size: 22),
                ),
                const SizedBox(height: 10),
                Text(a.label,
                    textAlign: TextAlign.center,
                    style: PsgText.label(10,
                        letterSpacing: 0.2,
                        color: PsgColors.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Activity card ─────────────────────────────────────────────────────────
  Widget _activityCard() {
    final items = [
      _ActivityItem(
          'Room 304 Allocated',
          'Admin assigned Rahul S. to Room 304 (Block A) • 12 mins ago',
          PsgColors.primary),
      _ActivityItem(
          'Mess Notice Published',
          'Weekly menu update for Oct 21-27 • 1 hour ago',
          PsgColors.secondary),
      _ActivityItem(
          'New Maintenance Complaint',
          'Room 112: Water leakage reported • 3 hours ago',
          PsgColors.error),
    ];

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.history_rounded,
              color: PsgColors.primary, size: 20),
          const SizedBox(width: 8),
          Text('Recent System Activity',
              style:
                  PsgText.headline(16, color: PsgColors.primary, weight: FontWeight.w800)),
        ]),
        const SizedBox(height: 20),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Container(
                    width: 4, height: 40,
                    margin: const EdgeInsets.only(right: 14, top: 3),
                    decoration: BoxDecoration(
                        color: item.color.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(2))),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(item.title,
                        style: PsgText.label(13,
                            color: PsgColors.onSurface)),
                    const SizedBox(height: 2),
                    Text(item.subtitle,
                        style: PsgText.body(12,
                            color: PsgColors.onSurfaceVariant)),
                  ]),
                ),
              ]),
            )),
      ]),
    );
  }
}

class _Action {
  final String label;
  final IconData icon;
  final String route;
  const _Action(this.label, this.icon, this.route);
}

class _Metric {
  final String label;
  final IconData icon;
  final Stream<QuerySnapshot> stream;
  final Color color;
  const _Metric(this.label, this.icon, this.stream, this.color);
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final Color color;
  const _ActivityItem(this.title, this.subtitle, this.color);
}
