// ─────────────────────────────────────────────────────────────────────────────
// Leave Request Screen  —  Glassmorphism UI
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../app/app_routes.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../../../../core/design/psg_design_system.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  double _scrollOffset = 0;

  DateTime? _fromDate;
  DateTime? _toDate;
  String _reason = 'Home Visit';
  bool _submitting = false;
  final _descController = TextEditingController();

  final _reasons = [
    'Home Visit',
    'Medical Emergency',
    'Academic Event',
    'Others',
  ];

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
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _descController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // ── Submit ───────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_fromDate == null || _toDate == null) {
      _snack('Please select both From and To dates.');
      return;
    }
    if (_toDate!.isBefore(_fromDate!)) {
      _snack('End date must be after start date.');
      return;
    }
    final uid = AuthProviderController.of(context).user?.uid;
    if (uid == null) return;

    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance.collection('leave_requests').add({
        'userId': uid,
        'startDate': Timestamp.fromDate(_fromDate!),
        'endDate': Timestamp.fromDate(_toDate!),
        'reason': _reason,
        'leaveType': _descController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _fromDate = null;
        _toDate = null;
        _descController.clear();
        setState(() {});
        _snack('Leave application submitted!', isSuccess: true);
      }
    } catch (e) {
      if (mounted) _snack('Submission failed. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? PsgColors.green : PsgColors.error,
      ),
    );
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate ?? now : _toDate ?? (_fromDate ?? now),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: PsgColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => isFrom ? _fromDate = picked : _toDate = picked);
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final uid = AuthProviderController.of(context).user?.uid ?? '';

    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          scrollOffset: _scrollOffset,
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
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 88,
                bottom: 40,
                left: 24,
                right: 24,
              ),
              children: [
                // ── Page header
                StaggeredEntry(
                  index: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leave Application',
                        style: PsgText.headline(30, color: PsgColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Request formal permission for hostel absence.',
                        style: PsgText.body(
                          14,
                          color: PsgColors.onSurfaceVariant,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Form card
                StaggeredEntry(index: 1, child: GlassCard(child: _buildForm())),
                const SizedBox(height: 28),

                // ── History
                StaggeredEntry(
                  index: 2,
                  child: PsgSectionHeader(
                    title: 'My Leave History',
                    action: 'View All',
                  ),
                ),
                const SizedBox(height: 14),

                StreamBuilder<QuerySnapshot>(
                  stream: uid.isNotEmpty
                      ? FirebaseFirestore.instance
                          .collection('leave_requests')
                          .where('userId', isEqualTo: uid)
                          .snapshots()
                      : const Stream.empty(),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Text(
                          'Failed to load leave history.',
                          style: PsgText.body(14, color: PsgColors.error),
                        ),
                      );
                    }
                    final docs = snap.data?.docs ?? [];
                    final sorted = [...docs]..sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aT =
                            (aData['createdAt'] as Timestamp?)?.toDate() ??
                                DateTime(2000);
                        final bT =
                            (bData['createdAt'] as Timestamp?)?.toDate() ??
                                DateTime(2000);
                        return bT.compareTo(aT);
                      });

                    if (sorted.isEmpty) {
                      return Center(
                        child: Text(
                          'No leave requests yet.',
                          style: PsgText.body(
                            14,
                            color: PsgColors.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: sorted.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final start =
                            (data['startDate'] as Timestamp?)?.toDate();
                        final end = (data['endDate'] as Timestamp?)?.toDate();
                        if (start == null || end == null) {
                          return const SizedBox.shrink();
                        }

                        final status = data['status'] as String? ?? 'pending';
                        final reason = data['reason'] as String? ?? '';
                        final desc = data['leaveType'] as String? ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      reason,
                                      style: PsgText.label(
                                        14,
                                        color: PsgColors.onSurface,
                                      ),
                                    ),
                                    _statusPill(status),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${DateFormat('dd MMM yy').format(start)} → ${DateFormat('dd MMM yy').format(end)}',
                                  style: PsgText.body(
                                    12,
                                    color: PsgColors.onSurfaceVariant,
                                  ),
                                ),
                                if (desc.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    desc,
                                    style: PsgText.body(
                                      12,
                                      color: PsgColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = PsgColors.green;
        break;
      case 'rejected':
        color = PsgColors.error;
        break;
      default:
        color = PsgColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: PsgText.label(9, letterSpacing: 0.5, color: color),
      ),
    );
  }

  // ── Form ─────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date pickers
        Row(
          children: [
            Expanded(
              child: _datePicker('Date From', _fromDate, () => _pickDate(true)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _datePicker('Date To', _toDate, () => _pickDate(false)),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Reason dropdown
        Text(
          'REASON FOR LEAVE',
          style: PsgText.label(9, letterSpacing: 1.4, color: PsgColors.primary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButton<String>(
            value: _reason,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(
              Icons.expand_more_rounded,
              color: PsgColors.outline,
            ),
            style: PsgText.body(
              14,
              color: PsgColors.onSurface,
              weight: FontWeight.w500,
            ),
            items: _reasons
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => _reason = v ?? _reason),
          ),
        ),
        const SizedBox(height: 18),

        // Description
        Text(
          'BRIEFLY EXPLAIN…',
          style: PsgText.label(9, letterSpacing: 1.4, color: PsgColors.primary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descController,
          maxLines: 3,
          style: PsgText.body(
            14,
            color: PsgColors.onSurface,
            weight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Provide additional details for your request',
            hintStyle: PsgText.body(13, color: PsgColors.outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.white.withValues(alpha: 0.40),
            filled: true,
          ),
        ),
        const SizedBox(height: 22),

        PsgFilledButton(
          label: 'Submit Leave Application',
          icon: Icons.send_rounded,
          loading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _datePicker(String label, DateTime? value, VoidCallback onTap) {
    final fmt = value != null ? DateFormat('dd MMM yy').format(value) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: PsgText.label(9, letterSpacing: 1.4, color: PsgColors.primary),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(14),
              border: value != null
                  ? Border.all(color: PsgColors.primaryContainer, width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: value != null
                      ? PsgColors.primaryContainer
                      : PsgColors.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  fmt ?? 'Select date',
                  style: PsgText.body(
                    13,
                    color:
                        value != null ? PsgColors.onSurface : PsgColors.outline,
                    weight: value != null ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
