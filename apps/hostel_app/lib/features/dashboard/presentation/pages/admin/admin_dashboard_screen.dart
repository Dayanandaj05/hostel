// ─────────────────────────────────────────────────────────────────────────────
// Admin Dashboard  —  Glassmorphism UI  |  Mock-Offline Compatible
// ─────────────────────────────────────────────────────────────────────────────
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
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
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
    _Action('Token Inventory', Icons.inventory_2_rounded, AppRoutes.adminFoodTokens),
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
                if (mounted && context.mounted) context.go(AppRoutes.login);
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
                // ── Headline
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
                        'Welcome Administrator. '
                        'Here\'s your hostel dashboard.',
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

                // ── Metrics cards
                StaggeredEntry(index: 1, child: _metricsGrid()),
                const SizedBox(height: 28),

                // ── Admin actions
                StaggeredEntry(
                  index: 2,
                  child: PsgSectionHeader(
                    title: 'Administrative Actions',
                    action: 'Help',
                  ),
                ),
                const SizedBox(height: 10),
                StaggeredEntry(index: 3, child: _actionsGrid()),
                const SizedBox(height: 28),

                // ── Summary info
                StaggeredEntry(
                  index: 4,
                  child: PsgSectionHeader(title: 'System Statistics'),
                ),
                const SizedBox(height: 14),
                StaggeredEntry(index: 5, child: _activityCard()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricsGrid() {
    final metrics = [
      _Metric(
        'Total Students',
        Icons.group_rounded,
        '450',
        const Color(0xFF003F87),
      ),
      _Metric('Total Rooms', Icons.bed_rounded, '200', const Color(0xFF4F46E5)),
      _Metric(
        'Pending Leaves',
        Icons.event_busy_rounded,
        '12',
        PsgColors.error,
      ),
      _Metric(
        'Open Complaints',
        Icons.report_problem_rounded,
        '8',
        const Color(0xFFB45309),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
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
                    child: Text(
                      m.label,
                      style: PsgText.label(
                        9,
                        letterSpacing: 1.2,
                        color: PsgColors.secondary,
                      ),
                    ),
                  ),
                  Icon(m.icon, color: m.color.withValues(alpha: 0.3), size: 28),
                ],
              ),
              const Spacer(),
              Text(m.value, style: PsgText.headline(36, color: m.color)),
            ],
          ),
        );
      },
    );
  }

  Widget _actionsGrid() {
    return Column(
      children: _actions
          .asMap()
          .entries
          .map((entry) {
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
          })
          .toList(growable: false),
    );
  }

  Widget _activityCard() {
    final items = [
      _ActivityItem(
        'Room Allocation',
        'Assigned Rahul S. to Room 304 (Block A)',
        PsgColors.primary,
      ),
      _ActivityItem(
        'Menu Published',
        'Weekly menu for Oct 22-28 posted',
        PsgColors.secondary,
      ),
      _ActivityItem(
        'New Complaint',
        'Room 112: Water leakage reported',
        PsgColors.error,
      ),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: PsgColors.primary,
                size: 20,
              ),
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
          ...items.map(
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
                        Text(
                          item.title,
                          style: PsgText.label(13, color: PsgColors.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: PsgText.body(
                            12,
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
  final String value;
  final Color color;
  const _Metric(this.label, this.icon, this.value, this.color);
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final Color color;
  const _ActivityItem(this.title, this.subtitle, this.color);
}
