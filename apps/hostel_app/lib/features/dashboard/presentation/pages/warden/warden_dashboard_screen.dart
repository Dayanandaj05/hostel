// ─────────────────────────────────────────────────────────────────────────────
// Warden Dashboard  —  Glassmorphism UI  |  Mock-Offline Compatible
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
          child: SlideTransition(position: _slideAnim, child: _buildBody()),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
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
                'Operations Command',
                style: PsgText.headline(30, color: PsgColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage student requests and facility updates.',
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

        // ── Summary metric cards
        StaggeredEntry(index: 1, child: _summaryRow()),
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

        _buildMockLeavesSection(),
      ],
    );
  }

  Widget _buildMockLeavesSection() {
    // Mock sample leave requests
    final sampleLeaves = [
      _MockLeave('Rajesh Kumar', 'Oct 22', 'Oct 25', 4, 'Home visit'),
      _MockLeave('Priya Sharma', 'Oct 24', 'Oct 26', 3, 'Medical emergency'),
      _MockLeave('Arun Singh', 'Oct 25', 'Oct 27', 3, 'Family event'),
    ];

    if (sampleLeaves.isEmpty) {
      return GlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: PsgColors.green.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'All caught up!',
              style: PsgText.headline(
                16,
                color: PsgColors.onSurfaceVariant,
                weight: FontWeight.w700,
              ),
            ),
            Text(
              'No pending leave requests.',
              style: PsgText.body(13, color: PsgColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(sampleLeaves.length, (i) {
        final leave = sampleLeaves[i];
        return StaggeredEntry(
          index: i + 3,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _leaveCard(leave),
          ),
        );
      }),
    );
  }

  Widget _leaveCard(_MockLeave leave) {
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PsgAvatarInitials(name: leave.name, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave.name,
                      style: PsgText.headline(
                        15,
                        weight: FontWeight.w800,
                        color: PsgColors.primary,
                      ),
                    ),
                    Text(
                      leave.reason,
                      style: PsgText.body(
                        12,
                        color: PsgColors.onSurfaceVariant,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: PsgColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${leave.from} – ${leave.to}  (${leave.days} days)',
                style: PsgText.label(
                  12,
                  color: PsgColors.secondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _actionBtn(
                label: 'Reject',
                onTap: () => _showAction('Leave request rejected'),
                isOutlined: true,
              ),
              const SizedBox(width: 10),
              _actionBtn(
                label: 'Approve',
                onTap: () => _showAction('Leave request approved'),
                isOutlined: false,
              ),
            ],
          ),
        ],
      ),
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
          borderRadius: BorderRadius.circular(999),
          border: isOutlined
              ? Border.all(color: PsgColors.error.withValues(alpha: 0.3))
              : null,
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                    color: PsgColors.primaryContainer.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Text(
          label,
          style: PsgText.label(
            13,
            color: isOutlined ? PsgColors.error : Colors.white,
          ),
        ),
      ),
    );
  }

  void _showAction(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _summaryRow() {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            'Pending Leaves',
            Icons.departure_board_rounded,
            count: '5',
            tagLabel: 'Review',
            tagColor: PsgColors.error,
            tagBg: const Color(0xFFFFDAD6),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            'Mess Requests',
            Icons.restaurant_rounded,
            count: '3',
            tagLabel: 'Pending',
            tagColor: PsgColors.secondary,
            tagBg: const Color(0xFFE0EEFF),
            iconColor: PsgColors.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            'Complaints',
            Icons.report_rounded,
            count: '8',
            tagLabel: 'Priority',
            tagColor: Colors.white,
            tagBg: PsgColors.error,
            iconColor: PsgColors.error,
          ),
        ),
      ],
    );
  }

  Widget _metricCard(
    String label,
    IconData icon, {
    required String count,
    required String tagLabel,
    required Color tagColor,
    required Color tagBg,
    Color? iconColor,
  }) {
    final effectiveIconColor = iconColor ?? PsgColors.primary;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: effectiveIconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(count, style: PsgText.headline(32, color: PsgColors.primary)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tagLabel,
              style: PsgText.label(8, letterSpacing: 0.5, color: tagColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockLeave {
  final String name;
  final String from;
  final String to;
  final int days;
  final String reason;
  const _MockLeave(this.name, this.from, this.to, this.days, this.reason);
}
