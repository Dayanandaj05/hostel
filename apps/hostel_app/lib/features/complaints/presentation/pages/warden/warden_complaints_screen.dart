import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/complaint_controller.dart';
import '../../../domain/entities/complaint_model.dart';

class WardenComplaintsScreen extends StatefulWidget {
  const WardenComplaintsScreen({super.key});

  @override
  State<WardenComplaintsScreen> createState() => _WardenComplaintsScreenState();
}

class _WardenComplaintsScreenState extends State<WardenComplaintsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ComplaintController>().watchComplaints();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplaintController>(
      builder: (context, controller, _) {
        final complaints = controller.complaints;

        return Scaffold(
          appBar: AppBar(title: const Text('Manage Complaints')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: complaints.isEmpty
                ? const Center(
                    child: Text('No complaints found.'),
                  )
                : ListView.separated(
                    itemCount: complaints.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final complaint = complaints[index];
                      return _ComplaintCard(
                        complaint: complaint,
                        isUpdating: controller.isUpdating,
                        onStatusChanged: (status) async {
                          final messenger = ScaffoldMessenger.of(context);
                          await controller.updateStatus(
                            complaintId: complaint.id,
                            status: status,
                          );

                          if (!mounted) return;

                          final text = controller.errorMessage ??
                              controller.successMessage ??
                              'Updated';
                          messenger.showSnackBar(
                            SnackBar(content: Text(text)),
                          );
                        },
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({
    required this.complaint,
    required this.isUpdating,
    required this.onStatusChanged,
  });

  final ComplaintModel complaint;
  final bool isUpdating;
  final ValueChanged<ComplaintStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final createdAt = complaint.createdAt;
    final createdLabel = createdAt == null
        ? 'Unknown date'
        : '${createdAt.day.toString().padLeft(2, '0')}/'
            '${createdAt.month.toString().padLeft(2, '0')}/'
            '${createdAt.year}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              complaint.title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(complaint.description),
            const SizedBox(height: 12),
            Text(
              'Submitted by: ${complaint.userId} • $createdLabel',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ComplaintStatus>(
                    initialValue: complaint.status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: ComplaintStatus.values
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(),
                    onChanged: isUpdating
                        ? null
                        : (status) {
                            if (status == null) return;
                            if (status == complaint.status) return;
                            onStatusChanged(status);
                          },
                  ),
                ),
                if (isUpdating) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
