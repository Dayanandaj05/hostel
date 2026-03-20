import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/app_routes.dart';

class WardenMessApplicationsScreen extends StatelessWidget {
  const WardenMessApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D2137),
          foregroundColor: Colors.white,
          title: const Text('Mess Applications'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.go(AppRoutes.wardenHome),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_rounded),
              onPressed: () => context.go(AppRoutes.wardenHome),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Color(0xFF009688),
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MessAppList(status: 'pending'),
            _MessAppList(status: 'approved'),
            _MessAppList(status: 'rejected'),
          ],
        ),
      ),
    );
  }
}

class _MessAppList extends StatelessWidget {
  const _MessAppList({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mess_applications')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        // Client-side sort
        final sorted = List.from(docs);
        sorted.sort((a, b) {
          final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
          final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
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
                Icon(Icons.restaurant_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No $status applications',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
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
            return _MessAppCard(
              docId: doc.id,
              data: data,
              showActions: status == 'pending',
            );
          },
        );
      },
    );
  }
}

class _MessAppCard extends StatefulWidget {
  const _MessAppCard({
    required this.docId,
    required this.data,
    required this.showActions,
  });
  final String docId;
  final Map<String, dynamic> data;
  final bool showActions;

  @override
  State<_MessAppCard> createState() => _MessAppCardState();
}

class _MessAppCardState extends State<_MessAppCard> {
  bool _processing = false;

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _processing = true);
    try {
      await FirebaseFirestore.instance
          .collection('mess_applications')
          .doc(widget.docId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If approved, also update the student's messType in users collection
      if (newStatus == 'approved') {
        final studentId = widget.data['studentId'] as String?;
        if (studentId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .update({'messType': 'North Indian'});
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application $newStatus.'),
            backgroundColor:
                newStatus == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.data['studentName'] as String? ?? 'Student';
    final roll = widget.data['rollNumber'] as String? ?? '--';
    final current = widget.data['currentMess'] as String? ?? '--';
    final requested = widget.data['requestedMess'] as String? ?? 'North Indian';
    final remarks = widget.data['remarks'] as String? ?? '';
    final status = widget.data['status'] as String? ?? 'pending';
    final ts = widget.data['createdAt'] as Timestamp?;
    final dateStr = ts == null
        ? '--'
        : '${ts.toDate().day.toString().padLeft(2, '0')}/'
            '${ts.toDate().month.toString().padLeft(2, '0')}/'
            '${ts.toDate().year}';

    final statusColor = switch (status) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.orange,
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
            // Header row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF009688).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Mess Change',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _row(Icons.person_rounded, 'Student', name),
            const SizedBox(height: 6),
            _row(Icons.badge_rounded, 'Roll Number', roll),
            const SizedBox(height: 6),
            _row(Icons.restaurant_rounded, 'Current Mess', current),
            const SizedBox(height: 6),
            _row(Icons.swap_horiz_rounded, 'Requested', requested),
            const SizedBox(height: 6),
            _row(Icons.calendar_today_rounded, 'Applied On', dateStr),

            if (remarks.isNotEmpty) ...[
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
                    Text('Student Remarks',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(remarks,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],

            if (widget.showActions) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _processing ? null : () => _updateStatus('rejected'),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _processing ? null : () => _updateStatus('approved'),
                      icon: _processing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded, size: 18),
                      label:
                          Text(_processing ? 'Processing...' : 'Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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
        Text('$label: ',
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
