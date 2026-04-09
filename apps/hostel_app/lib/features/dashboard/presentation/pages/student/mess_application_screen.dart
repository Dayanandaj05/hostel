import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hostel_app/core/design/psg_design_system.dart';
import 'package:hostel_app/app/app_routes.dart';
import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';
import 'package:hostel_app/features/student/data/student_profile_provider.dart';

class MessApplicationScreen extends StatefulWidget {
  const MessApplicationScreen({super.key});

  @override
  State<MessApplicationScreen> createState() => _MessApplicationScreenState();
}

class _MessApplicationScreenState extends State<MessApplicationScreen> {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;
  final _remarksController = TextEditingController();
  bool _isLoading = false;
  bool _isAgreed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(
      () => setState(() => _scrollOffset = _scrollController.offset),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms before submitting.'),
        ),
      );
      return;
    }

    final user = context.read<AuthProviderController>().user;
    final profile = context.read<StudentProfileProvider>();
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final existing = await FirebaseFirestore.instance
          .collection('mess_applications')
          .where('studentId', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'approved']).get();
      if (existing.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('You already have a pending or approved application.'),
            ),
          );
        }
        return;
      }

      await FirebaseFirestore.instance.collection('mess_applications').add({
        'studentId': user.uid,
        'studentName': profile.displayName,
        'rollNumber': profile.rollNumber,
        'currentMess': profile.messType,
        'requestedMess': 'North Indian',
        'status': 'pending',
        'remarks': _remarksController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _remarksController.clear();
        setState(() => _isAgreed = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted! Awaiting warden approval.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProviderController>().user;
    final profile = context.watch<StudentProfileProvider>();
    final uid = user?.uid ?? '';

    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          scrollOffset: _scrollOffset,
          title: 'Mess Application',
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: PsgColors.primary,
              size: 20,
            ),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.studentHome),
          ),
        ),
        body: uid.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('mess_applications')
                    .where('studentId', isEqualTo: uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load applications.',
                        style: PsgText.body(14, color: PsgColors.error),
                      ),
                    );
                  }

                  final docs = snap.data?.docs ?? [];
                  final activeApp = docs.isNotEmpty &&
                          (['pending', 'approved'].contains(
                            ((docs.first.data()
                                        as Map<String, dynamic>)['status']
                                    as String?) ??
                                'pending',
                          ))
                      ? docs.first
                      : null;
                  final historyDocs =
                      activeApp != null ? docs.skip(1).toList() : docs;

                  return ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 88,
                      bottom: 40,
                      left: 20,
                      right: 20,
                    ),
                    children: [
                      Text(
                        'Mess Switch Request',
                        style: PsgText.headline(28, color: PsgColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Apply to switch from South Indian to North Indian mess.',
                        style:
                            PsgText.body(13, color: PsgColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      if (activeApp != null) ...[
                        _buildStatusTracker(
                            activeApp.data() as Map<String, dynamic>),
                        const SizedBox(height: 24),
                      ],
                      if (activeApp == null) ...[
                        GlassCard(child: _buildForm(profile)),
                        const SizedBox(height: 24),
                      ],
                      if (historyDocs.isNotEmpty) ...[
                        Text(
                          'Application History',
                          style: PsgText.label(
                            12,
                            letterSpacing: 1.2,
                            color: PsgColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...historyDocs.map(
                          (doc) => _buildHistoryCard(
                              doc.data() as Map<String, dynamic>),
                        ),
                      ],
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildStatusTracker(Map<String, dynamic> data) {
    final status = data['status'] as String? ?? 'pending';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final isPending = status == 'pending';
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';

    final statusColor = isApproved
        ? Colors.green
        : isRejected
            ? Colors.red
            : Colors.amber;
    final statusIcon = isApproved
        ? Icons.check_circle_rounded
        : isRejected
            ? Icons.cancel_rounded
            : Icons.schedule_rounded;
    final statusText = isApproved
        ? 'Approved - Mess changed to North Indian'
        : isRejected
            ? 'Rejected by warden'
            : 'Under Review - Awaiting warden approval';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_rounded,
                  color: PsgColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Current Application',
                style: PsgText.label(
                  12,
                  letterSpacing: 1.0,
                  color: PsgColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _timelineDot(true, Colors.green, 'Applied'),
              _timelineLine(isPending || isApproved || isRejected),
              _timelineDot(
                isApproved || isRejected,
                isApproved
                    ? Colors.green
                    : isRejected
                        ? Colors.red
                        : Colors.grey,
                'Review',
              ),
              _timelineLine(isApproved || isRejected),
              _timelineDot(
                  isApproved, isApproved ? Colors.green : Colors.grey, 'Done'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(statusText,
                      style: PsgText.body(13, color: statusColor)),
                ),
              ],
            ),
          ),
          if (isRejected && data['rejectionReason'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: ${data['rejectionReason']}',
              style: PsgText.body(12, color: PsgColors.error),
            ),
          ],
          if (createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Applied on ${DateFormat('dd MMM yyyy').format(createdAt)}',
              style: PsgText.body(11, color: PsgColors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timelineDot(bool active, Color color, String label) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : Colors.white.withValues(alpha: 0.1),
            border:
                Border.all(color: active ? color : Colors.white24, width: 2),
          ),
          child: active
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: PsgText.body(9, color: PsgColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _timelineLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: active
            ? PsgColors.primary.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildForm(StudentProfileProvider profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR CURRENT MESS',
          style: PsgText.label(9, letterSpacing: 1.4, color: PsgColors.primary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.displayName,
                      style: PsgText.label(14, color: PsgColors.onSurface)),
                  Text(profile.rollNumber,
                      style:
                          PsgText.body(12, color: PsgColors.onSurfaceVariant)),
                ],
              ),
              Row(
                children: [
                  _messChip(profile.messType, Colors.amber),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white38, size: 16),
                  _messChip('North Indian', Colors.green),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'REASON (OPTIONAL)',
          style: PsgText.label(9, letterSpacing: 1.4, color: PsgColors.primary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _remarksController,
          maxLines: 3,
          style: PsgText.body(14, color: PsgColors.onSurface),
          decoration: InputDecoration(
            hintText: 'e.g. Dietary preference, health reasons...',
            hintStyle: PsgText.body(13, color: PsgColors.outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.white.withValues(alpha: 0.40),
            filled: true,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _isAgreed,
              onChanged: (v) => setState(() => _isAgreed = v ?? false),
              activeColor: PsgColors.primary,
              side: const BorderSide(color: PsgColors.outline),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'I understand this change is subject to warden approval and fixed for the billing cycle.',
                  style: PsgText.body(12, color: PsgColors.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        PsgFilledButton(
          label: 'Apply for North Indian Mess',
          icon: Icons.swap_horiz_rounded,
          loading: _isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _messChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: PsgText.label(10, letterSpacing: 0.3, color: color),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data) {
    final status = data['status'] as String? ?? 'rejected';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final color = status == 'approved' ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Row(
          children: [
            Icon(
              status == 'approved'
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              color: color,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'North Indian Mess Request',
                    style: PsgText.label(13, color: PsgColors.onSurface),
                  ),
                  if (createdAt != null)
                    Text(
                      DateFormat('dd MMM yyyy').format(createdAt),
                      style:
                          PsgText.body(11, color: PsgColors.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status.toUpperCase(),
                style: PsgText.label(9, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
