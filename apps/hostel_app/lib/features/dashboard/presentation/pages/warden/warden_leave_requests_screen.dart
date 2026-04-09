import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hostel_app/core/design/psg_design_system.dart';
import 'package:hostel_app/app/app_routes.dart';

class WardenLeaveRequestsScreen extends StatefulWidget {
  const WardenLeaveRequestsScreen({super.key});

  @override
  State<WardenLeaveRequestsScreen> createState() =>
      _WardenLeaveRequestsScreenState();
}

class _WardenLeaveRequestsScreenState extends State<WardenLeaveRequestsScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;
  late TabController _tabController;
  static const _tabs = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(
      () => setState(() => _scrollOffset = _scrollController.offset),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _stream(String filter) {
    final q = FirebaseFirestore.instance
        .collection('leave_requests')
        .orderBy('createdAt', descending: true);
    return q.snapshots();
  }

  Future<void> _approve(String docId) async {
    await FirebaseFirestore.instance
        .collection('leave_requests')
        .doc(docId)
        .update({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': FirebaseAuth.instance.currentUser?.uid,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave approved ✓'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _reject(String docId) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D1F35),
        title:
            const Text('Reject Leave', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Reason for rejection (optional)',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await FirebaseFirestore.instance
        .collection('leave_requests')
        .doc(docId)
        .update({
      'status': 'rejected',
      'rejectionReason': reasonCtrl.text.trim(),
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedBy': FirebaseAuth.instance.currentUser?.uid,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Leave rejected'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          scrollOffset: _scrollOffset,
          title: 'Leave Requests',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: PsgColors.primary, size: 20),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.wardenHome),
          ),
        ),
        body: Padding(
          padding:
              EdgeInsets.only(top: MediaQuery.of(context).padding.top + 88),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: PsgColors.primary,
                unselectedLabelColor: PsgColors.onSurfaceVariant,
                indicatorColor: PsgColors.secondary,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs
                      .map((filter) => _buildList(filter.toLowerCase()))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(String filter) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream(filter),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error: ${snap.error}',
              style: PsgText.body(14, color: PsgColors.error),
            ),
          );
        }
        var docs = snap.data?.docs ?? [];
        if (filter != 'all') {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['status'] as String? ?? 'pending') == filter;
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flight_takeoff_outlined,
                    size: 56, color: Colors.white24),
                const SizedBox(height: 12),
                Text(
                  'No ${filter == 'all' ? '' : filter} leave requests',
                  style: PsgText.body(15, color: PsgColors.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? 'pending';
            final start = (data['startDate'] as Timestamp?)?.toDate();
            final end = (data['endDate'] as Timestamp?)?.toDate();
            final reason = data['reason'] as String? ?? '';
            final desc = data['leaveType'] as String? ?? '';
            final isPending = status == 'pending';

            final dateRange = start != null && end != null
                ? '${DateFormat('dd MMM yyyy').format(start)} → ${DateFormat('dd MMM yyyy').format(end)}  (${end.difference(start).inDays + 1} days)'
                : 'Dates unavailable';

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            reason,
                            style:
                                PsgText.label(15, color: PsgColors.onSurface),
                          ),
                        ),
                        _statusChip(status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateRange,
                      style:
                          PsgText.body(12, color: PsgColors.onSurfaceVariant),
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style:
                            PsgText.body(12, color: PsgColors.onSurfaceVariant),
                      ),
                    ],
                    if (isPending) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _reject(doc.id),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _approve(doc.id),
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: const Text('Approve'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!isPending && data['rejectionReason'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Reason: ${data['rejectionReason']}',
                        style: PsgText.body(11, color: PsgColors.error),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusChip(String status) {
    final color = switch (status) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.amber,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: PsgText.label(9, letterSpacing: 0.8, color: color),
      ),
    );
  }
}
