import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WardenLeaveRequestsScreen extends StatefulWidget {
  const WardenLeaveRequestsScreen({super.key});

  @override
  State<WardenLeaveRequestsScreen> createState() => _WardenLeaveRequestsScreenState();
}

class _WardenLeaveRequestsScreenState extends State<WardenLeaveRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        foregroundColor: Colors.white,
        title: const Text('Leave Requests'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: const Color(0xFF009688),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _LeaveListView(statusFilter: 'pending'),
          const _LeaveListView(statusFilter: 'approved'),
          const _LeaveListView(statusFilter: 'rejected'),
        ],
      ),
    );
  }
}

class _LeaveListView extends StatelessWidget {
  const _LeaveListView({required this.statusFilter});
  final String statusFilter;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leave_requests')
          .where('status', isEqualTo: statusFilter)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load requests.'));
        }

        final docs = snapshot.data?.docs ?? [];

        // Client-side sort by createdAt descending
        final sorted = List.from(docs);
        sorted.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTs = aData['createdAt'] as Timestamp?;
          final bTs = bData['createdAt'] as Timestamp?;
          if (aTs == null && bTs == null) return 0;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return bTs.compareTo(aTs);
        });

        if (sorted.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No $statusFilter requests',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final doc = sorted[index];
            final data = doc.data() as Map<String, dynamic>;
            return _LeaveCard(
              docId: doc.id,
              data: data,
              showActions: statusFilter == 'pending',
            );
          },
        );
      },
    );
  }
}

class _LeaveCard extends StatefulWidget {
  const _LeaveCard({
    required this.docId,
    required this.data,
    required this.showActions,
  });
  final String docId;
  final Map<String, dynamic> data;
  final bool showActions;

  @override
  State<_LeaveCard> createState() => _LeaveCardState();
}

class _LeaveCardState extends State<_LeaveCard> {
  bool _processing = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _processing = true);
    try {
      await FirebaseFirestore.instance
          .collection('leave_requests')
          .doc(widget.docId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave request ${status == 'approved' ? 'approved' : 'rejected'}.'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  String _formatTs(Timestamp? ts) {
    if (ts == null) return '--';
    final dt = ts.toDate();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final startTs = widget.data['startDate'] as Timestamp?;
    final endTs = widget.data['endDate'] as Timestamp?;
    final reason = widget.data['reason'] as String? ?? '--';
    final leaveType = widget.data['leaveType'] as String? ?? 'Leave';
    final userId = widget.data['userId'] as String? ?? 'Unknown';
    final approvalManager = widget.data['approvalManager'] as String? ?? '--';
    final status = widget.data['status'] as String? ?? 'pending';

    final statusColor = switch (status) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.amber,
    };

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2137).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    leaveType,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF0D2137),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _row(Icons.person_outline, 'Student UID', userId),
            const SizedBox(height: 6),
            _row(Icons.calendar_today_outlined, 'From', _formatTs(startTs)),
            const SizedBox(height: 6),
            _row(Icons.calendar_today_outlined, 'To', _formatTs(endTs)),
            const SizedBox(height: 6),
            _row(Icons.supervisor_account_outlined, 'Approval Manager', approvalManager),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(reason, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            if (widget.showActions) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _processing ? null : () => _updateStatus('rejected'),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _processing ? null : () => _updateStatus('approved'),
                      icon: _processing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(_processing ? 'Processing...' : 'Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF009688)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
