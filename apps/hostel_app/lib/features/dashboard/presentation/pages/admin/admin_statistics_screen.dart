import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Hostel Statistics')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1200
              ? 4
              : constraints.maxWidth >= 760
                  ? 2
                  : 1;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.4,
                  ),
                  children: [
                    _StatCard(
                      title: 'Total Users',
                      icon: Icons.people_alt_rounded,
                      stream: firestore.collection('users').snapshots(),
                    ),
                    _StatCard(
                      title: 'Total Rooms',
                      icon: Icons.meeting_room_rounded,
                      stream: firestore.collection('rooms').snapshots(),
                    ),
                    _StatCard(
                      title: 'Pending Leaves',
                      icon: Icons.pending_actions_rounded,
                      stream: firestore
                          .collection('leave_requests')
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                    ),
                    _StatCard(
                      title: 'Open Complaints',
                      icon: Icons.report_problem_rounded,
                      stream: firestore.collection('complaints').where('status',
                          whereIn: ['pending', 'in_progress']).snapshots(),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.icon,
    required this.stream,
  });

  final String title;
  final IconData icon;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            final count = snapshot.data?.docs.length;
            final label = count == null ? '--' : '$count';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: scheme.primaryContainer,
                  ),
                  child: Icon(icon, color: scheme.onPrimaryContainer),
                ),
                const Spacer(),
                Text(
                  label,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
