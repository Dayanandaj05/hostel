import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hostel_app/app/app_routes.dart';
import 'package:hostel_app/core/design/psg_design_system.dart';
import 'package:intl/intl.dart';

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentMonthLabel = DateFormat('MMM yyyy').format(DateTime.now());
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          title: 'Analytics Dashboard',
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: PsgColors.primary,
              size: 20,
            ),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.adminHome),
          ),
        ),
        body: ListView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 88,
            left: 20,
            right: 20,
            bottom: 32,
          ),
          children: [
            Text(
              'Live System Analytics',
              style: PsgText.headline(28, color: PsgColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time operational insights from Firestore.',
              style: PsgText.body(13, color: PsgColors.onSurfaceVariant),
            ),
            Text(
              'Snapshot: $currentMonthLabel',
              style: PsgText.body(11, color: PsgColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _buildKpiStrip(),
            const SizedBox(height: 20),
            _buildLeaveAnalytics(),
            const SizedBox(height: 14),
            _buildComplaintsAnalytics(),
            const SizedBox(height: 14),
            _buildMessApplicationAnalytics(),
            const SizedBox(height: 14),
            _buildTokenRevenueAnalytics(),
            const SizedBox(height: 14),
            _buildHostelDayAnalytics(),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiStrip() {
    return SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _kpiChip(
            label: 'Total Students',
            chipColor: PsgColors.primary,
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'student')
                .snapshots(),
          ),
          _kpiChip(
            label: 'Total Wardens',
            chipColor: PsgColors.secondary,
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'warden')
                .snapshots(),
          ),
          _kpiChip(
            label: 'Total Rooms',
            chipColor: const Color(0xFF4F46E5),
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'student')
                .snapshots(),
            countBuilder: (docs) {
              return docs.where((d) {
                final room = d.data()['roomNumber'];
                return room != null && room.toString().trim().isNotEmpty;
              }).length;
            },
          ),
          _kpiChip(
            label: 'Hostel Day Passes',
            chipColor: const Color(0xFFEA580C),
            stream: FirebaseFirestore.instance
                .collection('day_entry_registrations')
                .snapshots(),
          ),
          _kpiChip(
            label: 'Active Tokens',
            chipColor: PsgColors.green,
            stream: FirebaseFirestore.instance
                .collection('food_tokens')
                .where('status', isEqualTo: 'active')
                .snapshots(),
          ),
          _kpiChip(
            label: 'Active Notices',
            chipColor: const Color(0xFFB45309),
            stream: FirebaseFirestore.instance
                .collection('notices')
                .where('isActive', isEqualTo: true)
                .snapshots(),
          ),
        ],
      ),
    );
  }

  Widget _kpiChip({
    required String label,
    required Color chipColor,
    required Stream<QuerySnapshot<Map<String, dynamic>>> stream,
    int Function(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs)?
        countBuilder,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        final docs = snap.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final count = countBuilder != null ? countBuilder(docs) : docs.length;
        return Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: chipColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (snap.connectionState == ConnectionState.waiting)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: PsgColors.primary,
                  ),
                )
              else
                Text(
                  snap.hasError ? '--' : '$count',
                  style: PsgText.headline(22, color: chipColor),
                ),
              Text(
                label,
                style: PsgText.label(
                  9,
                  letterSpacing: 0.8,
                  color: PsgColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaveAnalytics() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flight_takeoff_rounded,
                color: PsgColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Leave Analytics',
                style: PsgText.headline(
                  16,
                  color: PsgColors.primary,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('leave_requests')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PsgColors.primary,
                    ),
                  ),
                );
              }
              if (snap.hasError) {
                return Text(
                  '--',
                  style: PsgText.headline(24, color: PsgColors.error),
                );
              }

              final all = snap.data?.docs ?? [];
              final now = DateTime.now();
              final monthStart = DateTime(now.year, now.month, 1);

              final pending = all.where((d) {
                final data = d.data();
                return data['status'] == 'pending';
              }).length;

              final approvedThisMonth = all.where((d) {
                final data = d.data();
                if (data['status'] != 'approved') return false;
                final ts = data['createdAt'] as Timestamp?;
                if (ts == null) return false;
                return !ts.toDate().isBefore(monthStart);
              }).length;

              final rejected = all.where((d) {
                final data = d.data();
                return data['status'] == 'rejected';
              }).length;

              final total = all.length;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.3,
                children: [
                  _StatBox('Pending', pending, Colors.amber),
                  _StatBox(
                      'Approved\nThis Month', approvedThisMonth, Colors.green),
                  _StatBox('Rejected', rejected, Colors.red),
                  _StatBox('Total', total, PsgColors.primary),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsAnalytics() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.report_problem_rounded,
                color: PsgColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Complaints Analytics',
                style: PsgText.headline(
                  16,
                  color: PsgColors.primary,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance.collection('complaints').snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PsgColors.primary,
                    ),
                  ),
                );
              }
              if (snap.hasError) {
                return Text(
                  '--',
                  style: PsgText.headline(24, color: PsgColors.error),
                );
              }

              final all = snap.data?.docs ?? [];
              final pending =
                  all.where((d) => d.data()['status'] == 'pending').length;
              final inProgress =
                  all.where((d) => d.data()['status'] == 'in_progress').length;
              final resolved =
                  all.where((d) => d.data()['status'] == 'resolved').length;
              final total = all.length;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.3,
                children: [
                  _StatBox('Pending', pending, Colors.amber),
                  _StatBox('In Progress', inProgress, Colors.blue),
                  _StatBox('Resolved', resolved, Colors.green),
                  _StatBox('Total', total, PsgColors.primary),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessApplicationAnalytics() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.restaurant_rounded,
                color: PsgColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Mess Applications',
                style: PsgText.headline(
                  16,
                  color: PsgColors.primary,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('mess_applications')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PsgColors.primary,
                    ),
                  ),
                );
              }
              if (snap.hasError) {
                return Text(
                  '--',
                  style: PsgText.headline(24, color: PsgColors.error),
                );
              }

              final all = snap.data?.docs ?? [];
              final pending =
                  all.where((d) => d.data()['status'] == 'pending').length;
              final approved =
                  all.where((d) => d.data()['status'] == 'approved').length;
              final rejected =
                  all.where((d) => d.data()['status'] == 'rejected').length;
              final total = all.length;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.3,
                children: [
                  _StatBox('Pending', pending, Colors.amber),
                  _StatBox('Approved', approved, Colors.green),
                  _StatBox('Rejected', rejected, Colors.red),
                  _StatBox('Total', total, PsgColors.primary),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTokenRevenueAnalytics() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fastfood_rounded,
                color: PsgColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Token Bookings',
                style: PsgText.headline(
                  16,
                  color: PsgColors.primary,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('food_tokens')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PsgColors.primary,
                    ),
                  ),
                );
              }
              if (snap.hasError) {
                return Text(
                  '--',
                  style: PsgText.headline(24, color: PsgColors.error),
                );
              }

              final all = snap.data?.docs ?? [];
              final now = DateTime.now();
              final monthStart = DateTime(now.year, now.month, 1);

              final thisMonth = all.where((d) {
                final ts = d.data()['createdAt'] as Timestamp?;
                return ts != null && !ts.toDate().isBefore(monthStart);
              }).toList();

              final totalTokens = all.length;
              final thisMonthTokens = thisMonth.length;

              final totalRevenue = all.fold<double>(0, (acc, d) {
                return acc +
                    ((d.data()['totalPrice'] as num?)?.toDouble() ?? 0);
              });

              final thisMonthRevenue = thisMonth.fold<double>(0, (acc, d) {
                return acc +
                    ((d.data()['totalPrice'] as num?)?.toDouble() ?? 0);
              });

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _RevenueBox(
                          value: '₹${totalRevenue.toStringAsFixed(0)}',
                          label: 'Total Revenue',
                          color: PsgColors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RevenueBox(
                          value: '₹${thisMonthRevenue.toStringAsFixed(0)}',
                          label: 'This Month',
                          color: PsgColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.3,
                    children: [
                      _StatBox(
                          'Total Tokens', totalTokens, PsgColors.secondary),
                      _StatBox(
                          'This Month', thisMonthTokens, PsgColors.primary),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHostelDayAnalytics() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.celebration_rounded,
                color: PsgColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Hostel Day Registrations',
                style: PsgText.headline(
                  16,
                  color: PsgColors.primary,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('day_entry_registrations')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PsgColors.primary,
                    ),
                  ),
                );
              }
              if (snap.hasError) {
                return Text(
                  '--',
                  style: PsgText.headline(24, color: PsgColors.error),
                );
              }

              final all = snap.data?.docs ?? [];
              final total = all.length;
              final approved =
                  all.where((d) => d.data()['status'] == 'approved').length;
              final pending =
                  all.where((d) => d.data()['status'] == 'pending').length;

              final totalVisitors = all.fold<int>(0, (acc, d) {
                final visitors = d.data()['visitors'] as List? ?? [];
                return acc + visitors.length;
              });

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.3,
                children: [
                  _StatBox('Total Registrations', total, PsgColors.primary),
                  _StatBox('Approved', approved, Colors.green),
                  _StatBox('Pending', pending, Colors.amber),
                  _StatBox(
                      'Total Visitors', totalVisitors, PsgColors.secondary),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RevenueBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _RevenueBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: PsgText.headline(26, color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: PsgText.label(
              9,
              letterSpacing: 0.8,
              color: PsgColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$value', style: PsgText.headline(26, color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: PsgText.label(
              9,
              letterSpacing: 0.8,
              color: PsgColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
