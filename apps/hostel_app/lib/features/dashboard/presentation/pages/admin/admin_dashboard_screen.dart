import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/app_router.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProviderController.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 1300
              ? 5
              : width >= 1000
                  ? 3
                  : width >= 700
                      ? 2
                      : 1;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hostel Administration',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage users, roles, rooms, notices, and analytics.',
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
                        childAspectRatio: width >= 1000 ? 1.55 : 1.35,
                      ),
                      itemBuilder: (context, index) {
                        final card = _cards[index];
                        return _AdminActionCard(
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
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
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
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: scheme.primaryContainer,
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminDashboardCard {
  const _AdminDashboardCard({
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

const List<_AdminDashboardCard> _cards = [
  _AdminDashboardCard(
    title: 'Add Users',
    subtitle: 'Create new user records for students and staff.',
    icon: Icons.person_add_alt_1_rounded,
    route: AppRoutes.adminUsers,
  ),
  _AdminDashboardCard(
    title: 'Assign Roles',
    subtitle: 'Update role access for users in Firestore.',
    icon: Icons.admin_panel_settings_rounded,
    route: AppRoutes.adminRoles,
  ),
  _AdminDashboardCard(
    title: 'Allocate Rooms',
    subtitle: 'Assign room IDs to students quickly.',
    icon: Icons.meeting_room_rounded,
    route: AppRoutes.adminRooms,
  ),
  _AdminDashboardCard(
    title: 'Hostel Statistics',
    subtitle: 'View real-time operational counts and trends.',
    icon: Icons.query_stats_rounded,
    route: AppRoutes.adminDashboard,
  ),
  _AdminDashboardCard(
    title: 'Post Notices',
    subtitle: 'Publish announcements visible to all residents.',
    icon: Icons.campaign_rounded,
    route: AppRoutes.adminNotices,
  ),
];
