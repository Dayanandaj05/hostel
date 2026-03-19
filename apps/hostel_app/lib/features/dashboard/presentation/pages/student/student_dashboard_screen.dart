import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/app_router.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProviderController.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: authProvider.isLoading
                ? null
                : () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = _gridColumnsForWidth(constraints.maxWidth);
            final cardAspectRatio = constraints.maxWidth >= 1200
                ? 1.8
                : constraints.maxWidth >= 800
                    ? 1.5
                    : 1.25;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your hostel tasks from one place.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _cards.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: cardAspectRatio,
                        ),
                        itemBuilder: (context, index) {
                          final card = _cards[index];
                          return _DashboardActionCard(
                            title: card.title,
                            subtitle: card.subtitle,
                            icon: card.icon,
                            onTap: () => context.go(card.route),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  int _gridColumnsForWidth(double width) {
    if (width >= 1100) return 4;
    if (width >= 700) return 2;
    return 1;
  }
}

class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCardItem {
  const _DashboardCardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

const List<_DashboardCardItem> _cards = [
  _DashboardCardItem(
    title: 'Apply Leave',
    subtitle: 'Request permission for leave and track status.',
    icon: Icons.event_available_rounded,
    route: AppRoutes.studentLeave,
  ),
  _DashboardCardItem(
    title: 'Submit Complaint',
    subtitle: 'Report hostel issues and follow resolutions.',
    icon: Icons.report_problem_rounded,
    route: AppRoutes.studentComplaints,
  ),
  _DashboardCardItem(
    title: 'View Notices',
    subtitle: 'Read latest announcements from hostel staff.',
    icon: Icons.campaign_rounded,
    route: AppRoutes.studentNotices,
  ),
  _DashboardCardItem(
    title: 'View Room Details',
    subtitle: 'Check your room allocation and facilities.',
    icon: Icons.meeting_room_rounded,
    route: AppRoutes.studentRoom,
  ),
];
