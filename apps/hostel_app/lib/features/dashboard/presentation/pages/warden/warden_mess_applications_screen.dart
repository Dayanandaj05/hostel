import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hostel_app/core/design/psg_design_system.dart';
import 'package:hostel_app/app/app_routes.dart';

class WardenMessApplicationsScreen extends StatefulWidget {
  const WardenMessApplicationsScreen({super.key, this.isAdminView = false});

  final bool isAdminView;

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
    _scrollController.addListener(() {
      final nextOffset = _scrollController.offset;
      if ((nextOffset - _scrollOffset).abs() < 8) return;
      if (!mounted) return;
      setState(() => _scrollOffset = nextOffset);
    });
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
      final appRef =
          FirebaseFirestore.instance.collection('mess_applications').doc(docId);
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;

      await FirebaseFirestore.instance.runTransaction((txn) async {
        final snap = await txn.get(appRef);
        if (!snap.exists) {
          return;
        }

        final data = snap.data() as Map<String, dynamic>;
        final currentDecisionKey =
            widget.isAdminView ? 'adminDecision' : 'wardenDecision';
        final otherDecisionKey =
            widget.isAdminView ? 'wardenDecision' : 'adminDecision';
        final reviewedByKey =
            widget.isAdminView ? 'adminReviewedBy' : 'wardenReviewedBy';
        final reviewedAtKey =
            widget.isAdminView ? 'adminReviewedAt' : 'wardenReviewedAt';

        final updates = <String, dynamic>{
          currentDecisionKey: 'approved',
          reviewedByKey: currentUid,
          reviewedAtKey: FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final otherDecision = (data[otherDecisionKey] as String?) ?? 'pending';
        final shouldFinalizeApproval = otherDecision == 'approved';
        DocumentReference<Map<String, dynamic>>? userRef;
        DocumentSnapshot<Map<String, dynamic>>? userSnap;

        if (shouldFinalizeApproval && studentId.isNotEmpty) {
          userRef =
              FirebaseFirestore.instance.collection('users').doc(studentId);
          userSnap = await txn.get(userRef);
        }

        if (shouldFinalizeApproval) {
          updates.addAll({
            'status': 'approved',
            'approvedBy': currentUid,
            'approvedAt': FieldValue.serverTimestamp(),
            'rejectionReason': null,
          });
        } else {
          updates['status'] = 'pending';
        }

        txn.update(appRef, updates);

        if (shouldFinalizeApproval && userRef != null && userSnap != null) {
          // Update only existing user profile docs; create is blocked by rules.
          if (userSnap.exists) {
            txn.update(userRef, {
              'messType': 'North Indian',
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isAdminView
                  ? 'Admin decision saved. Final approval completes after warden approval.'
                  : 'Warden decision saved. Final approval completes after admin approval.',
            ),
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
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF0D1F35),
          title: const Text(
            'Reject Application',
            style: TextStyle(color: Colors.white),
          ),
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
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      final rejectionReason = reasonCtrl.text.trim();
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;

      final currentDecisionKey =
          widget.isAdminView ? 'adminDecision' : 'wardenDecision';
      final reviewedByKey =
          widget.isAdminView ? 'adminReviewedBy' : 'wardenReviewedBy';
      final reviewedAtKey =
          widget.isAdminView ? 'adminReviewedAt' : 'wardenReviewedAt';
      final roleReasonKey =
          widget.isAdminView ? 'adminRejectionReason' : 'wardenRejectionReason';

      await FirebaseFirestore.instance
          .collection('mess_applications')
          .doc(docId)
          .update({
        'status': 'rejected',
        currentDecisionKey: 'rejected',
        reviewedByKey: currentUid,
        reviewedAtKey: FieldValue.serverTimestamp(),
        if (rejectionReason.isNotEmpty) roleReasonKey: rejectionReason,
        if (rejectionReason.isNotEmpty) 'rejectionReason': rejectionReason,
        'rejectedBy': currentUid,
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application rejected'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejection failed: $e')),
        );
      }
    } finally {
      reasonCtrl.dispose();
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
                : context.go(
                    widget.isAdminView
                        ? AppRoutes.adminHome
                        : AppRoutes.wardenHome,
                  ),
          ),
          title: widget.isAdminView
              ? 'Mess Applications (Admin)'
              : 'Mess Applications',
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
            final wardenDecision = data['wardenDecision'] as String? ??
                (status == 'approved'
                    ? 'approved'
                    : status == 'rejected'
                        ? 'rejected'
                        : 'pending');
            final adminDecision = data['adminDecision'] as String? ??
                (status == 'approved'
                    ? 'approved'
                    : status == 'rejected'
                        ? 'rejected'
                        : 'pending');
            final studentId = data['studentId'] as String? ?? '';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final periodStart = (data['periodStart'] as Timestamp?)?.toDate();

            final myDecision =
                widget.isAdminView ? adminDecision : wardenDecision;
            final canReview = status == 'pending' && myDecision == 'pending';

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
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _decisionChip('Warden', wardenDecision),
                        _decisionChip('Admin', adminDecision),
                      ],
                    ),
                    if (periodStart != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Target period: ${DateFormat('MMMM yyyy').format(periodStart)}',
                        style: PsgText.body(
                          11,
                          color: PsgColors.onSurfaceVariant,
                        ),
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
                    if (canReview) ...[
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
                        (data['rejectionReason']
                                ?.toString()
                                .trim()
                                .isNotEmpty ??
                            false)) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Reason: ${data['rejectionReason'].toString()}',
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

  Widget _decisionChip(String role, String decision) {
    final color = switch (decision) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.amber,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$role: ${decision.toUpperCase()}',
        style: PsgText.label(9, color: color),
      ),
    );
  }
}
