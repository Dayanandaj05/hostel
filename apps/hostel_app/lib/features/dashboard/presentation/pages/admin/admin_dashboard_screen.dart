// ─────────────────────────────────────────────────────────────────────────────
// Admin Dashboard  —  Live Firestore Analytics
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';

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
      () => setState(() => _scrollOffset = _scrollController.offset),
    );
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
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
    _Action(
      'Assign Roles',
      Icons.admin_panel_settings_rounded,
      AppRoutes.adminRoles,
    ),
    _Action('Allocate Rooms', Icons.meeting_room_rounded, AppRoutes.adminRooms),
    _Action(
      'Token Inventory',
      Icons.inventory_2_rounded,
      AppRoutes.adminFoodTokens,
    ),
    _Action('View Data', Icons.analytics_rounded, AppRoutes.adminDashboard),
    _Action('Post Notice', Icons.campaign_rounded, AppRoutes.adminNotices),
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
              icon: const Icon(
                Icons.logout_rounded,
                color: PsgColors.primary,
                size: 22,
              ),
              onPressed: () async {
                await AuthProviderController.of(context).signOut();
                if (mounted && context.mounted) {
                  context.go(AppRoutes.login);
                }
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
                bottom: 24,
                left: 24,
                right: 24,
              ),
              children: [
                StaggeredEntry(
                  index: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Overview',
                        style: PsgText.headline(30, color: PsgColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome Administrator. Here\'s your hostel dashboard.',
                        style: PsgText.body(
                          14,
                          color: PsgColors.onSurfaceVariant,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                StaggeredEntry(index: 1, child: _metricsGrid()),
                const SizedBox(height: 28),
                StaggeredEntry(
                  index: 2,
                  child: const PsgSectionHeader(
                    title: 'Administrative Actions',
                    action: 'Help',
                  ),
                ),
                const SizedBox(height: 10),
                StaggeredEntry(index: 3, child: _actionsGrid()),
                const SizedBox(height: 28),
                StaggeredEntry(
                  index: 4,
                  child: const PsgSectionHeader(title: 'System Statistics'),
                ),
                const SizedBox(height: 14),
                const StaggeredEntry(index: 5, child: _RecentActivityCard()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _liveMetricCard(
          label: 'Total Students',
          icon: Icons.group_rounded,
          color: const Color(0xFF003F87),
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'student')
              .snapshots(),
        ),
        _liveMetricCard(
          label: 'Pending Leaves',
          icon: Icons.event_busy_rounded,
          color: PsgColors.error,
          stream: FirebaseFirestore.instance
              .collection('leave_requests')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
        ),
        _liveMetricCard(
          label: 'Open Complaints',
          icon: Icons.report_problem_rounded,
          color: const Color(0xFFB45309),
          stream: FirebaseFirestore.instance.collection('complaints').where(
              'status',
              whereIn: const ['pending', 'in_progress']).snapshots(),
        ),
        _liveMetricCard(
          label: 'Hostel Day Registrations',
          icon: Icons.celebration_rounded,
          color: const Color(0xFF4F46E5),
          stream: FirebaseFirestore.instance
              .collection('day_entry_registrations')
              .snapshots(),
        ),
      ],
    );
  }

  Widget _liveMetricCard({
    required String label,
    required IconData icon,
    required Color color,
    required Stream<QuerySnapshot<Map<String, dynamic>>> stream,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
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
                    child: Text(
                      label,
                      style: PsgText.label(
                        9,
                        letterSpacing: 1.2,
                        color: PsgColors.secondary,
                      ),
                    ),
                  ),
                  Icon(icon, color: color.withValues(alpha: 0.3), size: 28),
                ],
              ),
              const Spacer(),
              if (snap.connectionState == ConnectionState.waiting)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: PsgColors.primary,
                  ),
                )
              else if (snap.hasError)
                Text('--', style: PsgText.headline(36, color: color))
              else
                Text('$count', style: PsgText.headline(36, color: color)),
            ],
          ),
        );
      },
    );
  }

  Widget _actionsGrid() {
    return Column(
      children: _actions.asMap().entries.map((entry) {
        final i = entry.key;
        final a = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            bottom: i == _actions.length - 1 ? 0 : 10,
          ),
          child: StaggeredEntry(
            index: i,
            child: GlassCard(
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              onTap: () => context.go(a.route),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: PsgColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(a.icon, color: PsgColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      a.label,
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
      }).toList(growable: false),
    );
  }
}

class _Action {
  final String label;
  final IconData icon;
  final String route;

  const _Action(this.label, this.icon, this.route);
}

class _RecentActivityCard extends StatefulWidget {
  const _RecentActivityCard();

  @override
  State<_RecentActivityCard> createState() => _RecentActivityCardState();
}

class _RecentActivityCardState extends State<_RecentActivityCard> {
  final List<_ActivityFeedItem> _items = [];
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subs =
      [];

  @override
  void initState() {
    super.initState();
    _listenCollection(
      'leave_requests',
      'Leave Request',
      Icons.flight_takeoff_rounded,
      PsgColors.error,
      titleField: 'reason',
    );
    _listenCollection(
      'complaints',
      'Complaint Filed',
      Icons.report_rounded,
      const Color(0xFFB45309),
      titleField: 'title',
    );
    _listenCollection(
      'notices',
      'Notice Posted',
      Icons.campaign_rounded,
      PsgColors.primary,
      titleField: 'title',
    );
    _listenCollection(
      'mess_applications',
      'Mess Application',
      Icons.restaurant_rounded,
      PsgColors.secondary,
      titleField: 'studentName',
    );
  }

  void _listenCollection(
    String col,
    String type,
    IconData icon,
    Color color, {
    required String titleField,
  }) {
    final sub = FirebaseFirestore.instance
        .collection(col)
        .orderBy('createdAt', descending: true)
        .limit(3)
        .snapshots()
        .listen((snap) {
      _items.removeWhere((i) => i.collection == col);
      for (final doc in snap.docs) {
        final data = doc.data();
        final ts = data['createdAt'] as Timestamp?;
        if (ts == null) continue;
        _items.add(
          _ActivityFeedItem(
            collection: col,
            type: type,
            title: data[titleField]?.toString() ?? type,
            createdAt: ts.toDate(),
            icon: icon,
            color: color,
          ),
        );
      }
      _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) setState(() {});
    });
    _subs.add(sub);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top5 = _items.take(5).toList();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded,
                  color: PsgColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recent Activity',
                style: PsgText.headline(
                  16,
                  color: PsgColors.primary,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (top5.isEmpty)
            Center(
              child: Text(
                'No recent activity',
                style: PsgText.body(13, color: PsgColors.onSurfaceVariant),
              ),
            )
          else
            ...top5.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      margin: const EdgeInsets.only(right: 14, top: 3),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(item.icon, size: 13, color: item.color),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.type,
                                  style: PsgText.label(
                                    13,
                                    color: PsgColors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.title,
                            style: PsgText.body(
                              12,
                              color: PsgColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _timeAgo(item.createdAt),
                            style: PsgText.body(
                              10,
                              color: PsgColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ActivityFeedItem {
  final String collection;
  final String type;
  final String title;
  final DateTime createdAt;
  final IconData icon;
  final Color color;

  const _ActivityFeedItem({
    required this.collection,
    required this.type,
    required this.title,
    required this.createdAt,
    required this.icon,
    required this.color,
  });
}
