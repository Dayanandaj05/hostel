import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hostel_app/app/app_routes.dart';
import 'package:hostel_app/core/design/psg_design_system.dart';
import 'package:intl/intl.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  int _viewIndex = 0;

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
              'Professional Insights',
              style: PsgText.headline(28, color: PsgColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              'Live metrics with chart-driven operational views.',
              style: PsgText.body(13, color: PsgColors.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              'Snapshot: $currentMonthLabel',
              style: PsgText.body(11, color: PsgColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _buildViewSwitcher(),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildActiveView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewSwitcher() {
    final labels = ['Overview', 'Operations', 'Revenue'];
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      borderRadius: 16,
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = _viewIndex == index;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => setState(() => _viewIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? PsgColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? PsgColors.primary.withValues(alpha: 0.35)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: PsgText.label(
                      12,
                      color: selected ? PsgColors.primary : PsgColors.secondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveView() {
    if (_viewIndex == 1) {
      return Column(
        key: const ValueKey('operations'),
        children: [
          _buildMessStatusCard(),
          const SizedBox(height: 14),
          _buildHostelDayCard(),
          const SizedBox(height: 14),
          _buildComplaintsBarCard(),
        ],
      );
    }

    if (_viewIndex == 2) {
      return Column(
        key: const ValueKey('revenue'),
        children: [
          _buildTokenRevenueTrendCard(),
          const SizedBox(height: 14),
          _buildTokenRevenueSummaryCard(),
        ],
      );
    }

    return Column(
      key: const ValueKey('overview'),
      children: [
        _buildKpiStrip(),
        const SizedBox(height: 14),
        _buildLeaveDonutCard(),
        const SizedBox(height: 14),
        _buildComplaintsBarCard(),
      ],
    );
  }

  Widget _buildKpiStrip() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _kpiChip(
            label: 'Students',
            chipColor: PsgColors.primary,
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'student')
                .snapshots(),
          ),
          _kpiChip(
            label: 'Wardens',
            chipColor: PsgColors.secondary,
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'warden')
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
            label: 'Hostel Day',
            chipColor: const Color(0xFFEA580C),
            stream: FirebaseFirestore.instance
                .collection('day_entry_registrations')
                .snapshots(),
          ),
          _kpiChip(
            label: 'Open Complaints',
            chipColor: const Color(0xFFD97706),
            stream: FirebaseFirestore.instance.collection('complaints').where(
                'status',
                whereIn: const ['pending', 'in_progress']).snapshots(),
          ),
        ],
      ),
    );
  }

  Widget _kpiChip({
    required String label,
    required Color chipColor,
    required Stream<QuerySnapshot<Map<String, dynamic>>> stream,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: chipColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (snap.connectionState == ConnectionState.waiting)
                const SizedBox(
                  height: 22,
                  width: 22,
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

  Widget _buildLeaveDonutCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
              'Leave Requests Overview', Icons.flight_takeoff_rounded),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('leave_requests')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _loadingState();
              }
              if (snap.hasError) {
                return _errorState();
              }

              final all = snap.data?.docs ?? [];
              final pending =
                  all.where((d) => d.data()['status'] == 'pending').length;
              final approved =
                  all.where((d) => d.data()['status'] == 'approved').length;
              final rejected =
                  all.where((d) => d.data()['status'] == 'rejected').length;
              final total = all.length;

              if (total == 0) {
                return _emptyState('No leave requests yet.');
              }

              return Column(
                children: [
                  SizedBox(
                    height: 210,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 52,
                        sectionsSpace: 2,
                        sections: [
                          _pie(pending.toDouble(), Colors.amber),
                          _pie(approved.toDouble(), Colors.green),
                          _pie(rejected.toDouble(), Colors.red),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _legendDot('Pending', pending, Colors.amber),
                      _legendDot('Approved', approved, Colors.green),
                      _legendDot('Rejected', rejected, Colors.red),
                      _legendDot('Total', total, PsgColors.primary),
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

  Widget _buildComplaintsBarCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Complaints Workflow', Icons.report_problem_rounded),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance.collection('complaints').snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _loadingState();
              }
              if (snap.hasError) {
                return _errorState();
              }

              final all = snap.data?.docs ?? [];
              final pending =
                  all.where((d) => d.data()['status'] == 'pending').length;
              final inProgress =
                  all.where((d) => d.data()['status'] == 'in_progress').length;
              final resolved =
                  all.where((d) => d.data()['status'] == 'resolved').length;
              final maxY = math.max(
                  1, math.max(pending, math.max(inProgress, resolved)));

              if (all.isEmpty) {
                return _emptyState('No complaints data yet.');
              }

              return Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        maxY: (maxY * 1.4).toDouble(),
                        alignment: BarChartAlignment.spaceAround,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const labels = [
                                  'Pending',
                                  'Progress',
                                  'Resolved',
                                ];
                                final i = value.toInt();
                                if (i < 0 || i >= labels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    labels[i],
                                    style: PsgText.label(
                                      10,
                                      color: PsgColors.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          _bar(0, pending.toDouble(), Colors.amber),
                          _bar(1, inProgress.toDouble(), Colors.blue),
                          _bar(2, resolved.toDouble(), Colors.green),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _legendDot('Pending', pending, Colors.amber),
                      _legendDot('In Progress', inProgress, Colors.blue),
                      _legendDot('Resolved', resolved, Colors.green),
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

  Widget _buildMessStatusCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Mess Application Status', Icons.restaurant_rounded),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('mess_applications')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _loadingState();
              }
              if (snap.hasError) {
                return _errorState();
              }

              final all = snap.data?.docs ?? [];
              final pending =
                  all.where((d) => d.data()['status'] == 'pending').length;
              final approved =
                  all.where((d) => d.data()['status'] == 'approved').length;
              final rejected =
                  all.where((d) => d.data()['status'] == 'rejected').length;

              if (all.isEmpty) {
                return _emptyState('No mess application data yet.');
              }

              return Column(
                children: [
                  SizedBox(
                    height: 205,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 48,
                        sectionsSpace: 2,
                        sections: [
                          _pie(pending.toDouble(), Colors.amber),
                          _pie(approved.toDouble(), Colors.green),
                          _pie(rejected.toDouble(), Colors.red),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _legendDot('Pending', pending, Colors.amber),
                      _legendDot('Approved', approved, Colors.green),
                      _legendDot('Rejected', rejected, Colors.red),
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

  Widget _buildHostelDayCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Hostel Day Registrations', Icons.celebration_rounded),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('day_entry_registrations')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _loadingState();
              }
              if (snap.hasError) {
                return _errorState();
              }

              final all = snap.data?.docs ?? [];
              final approved =
                  all.where((d) => d.data()['status'] == 'approved').length;
              final pending =
                  all.where((d) => d.data()['status'] == 'pending').length;
              final totalVisitors = all.fold<int>(0, (acc, d) {
                final visitors = d.data()['visitors'] as List? ?? [];
                return acc + visitors.length;
              });

              if (all.isEmpty) {
                return _emptyState('No hostel day registrations yet.');
              }

              final maxY = math.max(1, math.max(approved, pending));
              return Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        maxY: (maxY * 1.6).toDouble(),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const labels = ['Approved', 'Pending'];
                                final i = value.toInt();
                                if (i < 0 || i >= labels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    labels[i],
                                    style: PsgText.label(
                                      10,
                                      color: PsgColors.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          _bar(0, approved.toDouble(), Colors.green),
                          _bar(1, pending.toDouble(), Colors.amber),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Total Registrations',
                          value: '${all.length}',
                          color: PsgColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricTile(
                          label: 'Visitors',
                          value: '$totalVisitors',
                          color: PsgColors.secondary,
                        ),
                      ),
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

  Widget _buildTokenRevenueTrendCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Revenue Trend', Icons.show_chart_rounded),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('food_tokens')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _loadingState();
              }
              if (snap.hasError) {
                return _errorState();
              }

              final all = snap.data?.docs ?? [];
              if (all.isEmpty) {
                return _emptyState('No revenue data yet.');
              }

              final monthBuckets = _monthRevenueBuckets(all);
              final maxVal = monthBuckets.fold<double>(
                1,
                (acc, e) => math.max(acc, e.amount),
              );

              return SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxVal * 1.2,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: math.max(1, maxVal / 4),
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: PsgColors.secondary.withValues(alpha: 0.15),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= monthBuckets.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                monthBuckets[idx].label,
                                style: PsgText.label(
                                  10,
                                  color: PsgColors.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: PsgColors.primary,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) {
                            return FlDotCirclePainter(
                              radius: 3.6,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: PsgColors.primary,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: PsgColors.primary.withValues(alpha: 0.1),
                        ),
                        spots: List.generate(
                          monthBuckets.length,
                          (i) => FlSpot(i.toDouble(), monthBuckets[i].amount),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTokenRevenueSummaryCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Revenue Summary', Icons.payments_rounded),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('food_tokens')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _loadingState();
              }
              if (snap.hasError) {
                return _errorState();
              }

              final all = snap.data?.docs ?? [];
              if (all.isEmpty) {
                return _emptyState('No token records yet.');
              }

              final now = DateTime.now();
              final monthStart = DateTime(now.year, now.month, 1);

              final thisMonth = all.where((d) {
                final createdAt = _readTimestamp(d.data(), ['createdAt']);
                return createdAt != null &&
                    !createdAt.toDate().isBefore(monthStart);
              }).toList();

              final totalRevenue = all.fold<double>(0, (acc, d) {
                return acc +
                    ((d.data()['totalPrice'] as num?)?.toDouble() ?? 0);
              });

              final monthRevenue = thisMonth.fold<double>(0, (acc, d) {
                return acc +
                    ((d.data()['totalPrice'] as num?)?.toDouble() ?? 0);
              });

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Total Revenue',
                          value: '₹${totalRevenue.toStringAsFixed(0)}',
                          color: PsgColors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricTile(
                          label: 'Current Month',
                          value: '₹${monthRevenue.toStringAsFixed(0)}',
                          color: PsgColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Total Tokens',
                          value: '${all.length}',
                          color: PsgColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricTile(
                          label: 'This Month Tokens',
                          value: '${thisMonth.length}',
                          color: const Color(0xFF2563EB),
                        ),
                      ),
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

  List<_MonthRevenue> _monthRevenueBuckets(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i), 1);
      return DateTime(d.year, d.month, 1);
    });

    final totals = <DateTime, double>{
      for (final m in months) m: 0,
    };

    for (final doc in docs) {
      final data = doc.data();
      final createdAt = _readTimestamp(data, ['createdAt']);
      if (createdAt == null) {
        continue;
      }
      final key =
          DateTime(createdAt.toDate().year, createdAt.toDate().month, 1);
      if (!totals.containsKey(key)) {
        continue;
      }
      totals[key] =
          (totals[key] ?? 0) + ((data['totalPrice'] as num?)?.toDouble() ?? 0);
    }

    return months
        .map(
          (m) => _MonthRevenue(
            label: DateFormat('MMM').format(m),
            amount: totals[m] ?? 0,
          ),
        )
        .toList();
  }

  Timestamp? _readTimestamp(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is Timestamp) {
        return value;
      }
    }
    return null;
  }

  Widget _loadingState() {
    return const SizedBox(
      height: 120,
      child: Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: PsgColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _errorState() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          'Unable to load analytics.',
          style: PsgText.body(13, color: PsgColors.error),
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          message,
          style: PsgText.body(13, color: PsgColors.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: PsgColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: PsgText.headline(
            16,
            color: PsgColors.primary,
            weight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  PieChartSectionData _pie(double value, Color color) {
    return PieChartSectionData(
      value: value == 0 ? 0.01 : value,
      color: color,
      radius: 42,
      title: '',
      badgeWidget: value > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                value.toInt().toString(),
                style: PsgText.label(9, color: color),
              ),
            )
          : null,
      badgePositionPercentageOffset: 1.1,
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 28,
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              color,
              color.withValues(alpha: 0.75),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ],
    );
  }

  Widget _legendDot(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: PsgText.label(10, color: PsgColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
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
          Text(value, style: PsgText.headline(24, color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: PsgText.label(
              10,
              letterSpacing: 0.4,
              color: PsgColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthRevenue {
  final String label;
  final double amount;

  const _MonthRevenue({required this.label, required this.amount});
}
