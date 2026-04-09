import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hostel_app/core/design/psg_design_system.dart';
import 'package:hostel_app/app/app_routes.dart';

class WardenMessApplicationsScreen extends StatefulWidget {
  const WardenMessApplicationsScreen({super.key});

  @override
  State<WardenMessApplicationsScreen> createState() =>
      _WardenMessApplicationsScreenState();
}

class _WardenMessApplicationsScreenState
    extends State<WardenMessApplicationsScreen>
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

  Stream<QuerySnapshot> _stream() {
    return FirebaseFirestore.instance
        .collection('mess_applications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _approve(String docId, String studentId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final appRef =
          FirebaseFirestore.instance.collection('mess_applications').doc(docId);
      batch.update(appRef, {
        'status': 'approved',
        'approvedBy': FirebaseAuth.instance.currentUser?.uid,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      if (studentId.isNotEmpty) {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(studentId);
        batch.set(
            userRef, {'messType': 'North Indian'}, SetOptions(merge: true));
      }

      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application approved and mess updated.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e')),
        );
      }
    }
  }

  Future<void> _reject(String docId) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D1F35),
        title: const Text('Reject Application',
            style: TextStyle(color: Colors.white)),
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

    try {
      await FirebaseFirestore.instance
          .collection('mess_applications')
          .doc(docId)
          .update({
        'status': 'rejected',
        'rejectionReason': reasonCtrl.text.trim(),
        'rejectedBy': FirebaseAuth.instance.currentUser?.uid,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Application rejected'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejection failed: $e')),
        );
      }
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: PsgColors.primary, size: 20),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.wardenHome),
          ),
          title: 'Mess Applications',
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
      stream: _stream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: PsgColors.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load applications.',
              style: PsgText.body(14, color: PsgColors.error),
            ),
          );
        }

        var docs = snapshot.data?.docs ?? [];
        if (filter != 'all') {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? 'pending';
            return status == filter;
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant_menu_rounded,
                    size: 60, color: PsgColors.outline),
                const SizedBox(height: 16),
                Text(
                  'No ${filter == 'all' ? '' : filter} applications found',
                  style: PsgText.label(16, color: PsgColors.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: docs.length,
          itemBuilder: (_, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final studentName =
                data['studentName'] as String? ?? 'Unknown Student';
            final rollNumber = data['rollNumber'] as String? ?? 'N/A';
            final currentMess = data['currentMess'] as String? ?? 'Unknown';
            final requestedMess =
                data['requestedMess'] as String? ?? 'North Indian';
            final remarks = data['remarks'] as String? ?? '';
            final status = data['status'] as String? ?? 'pending';
            final studentId = data['studentId'] as String? ?? '';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: PsgText.label(15,
                                    color: PsgColors.onSurface),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                rollNumber,
                                style: PsgText.body(12,
                                    color: PsgColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        _statusChip(status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _messChip(currentMess, Colors.amber),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 16, color: Colors.white38),
                        ),
                        _messChip(requestedMess, Colors.green),
                      ],
                    ),
                    if (remarks.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        remarks,
                        style:
                            PsgText.body(12, color: PsgColors.onSurfaceVariant),
                      ),
                    ],
                    if (createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(createdAt),
                        style:
                            PsgText.body(11, color: PsgColors.onSurfaceVariant),
                      ),
                    ],
                    if (status == 'pending') ...[
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
                              onPressed: () => _approve(doc.id, studentId),
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
                    if (status == 'rejected' &&
                        (data['rejectionReason'] as String?)?.isNotEmpty ==
                            true) ...[
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

  Widget _messChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: PsgText.label(10, color: color),
      ),
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
