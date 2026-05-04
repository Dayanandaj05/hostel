import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hostel_app/core/design/psg_design_system.dart';
import '../../../../../app/app_routes.dart';

import '../../controllers/complaint_controller.dart';
import '../../../domain/entities/complaint_model.dart';

class WardenComplaintsScreen extends StatefulWidget {
  const WardenComplaintsScreen({super.key});

  @override
  State<WardenComplaintsScreen> createState() => _WardenComplaintsScreenState();
}

class _WardenComplaintsScreenState extends State<WardenComplaintsScreen> {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(
      () => setState(() => _scrollOffset = _scrollController.offset),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ComplaintController>().watchComplaints();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplaintController>(
      builder: (context, controller, _) {
        final complaints = controller.complaints;

        return MeshBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: PsgGlassAppBar(
              scrollOffset: _scrollOffset,
              title: 'Manage Complaints',
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: PsgColors.primary,
                  size: 20,
                ),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.wardenHome),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.home_rounded,
                    color: PsgColors.primary,
                  ),
                  onPressed: () => context.go(AppRoutes.wardenHome),
                ),
              ],
            ),
            body: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 88,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: complaints.isEmpty
                  ? Center(
                      child: GlassCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.report_outlined,
                              size: 56,
                              color: PsgColors.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No complaints found.',
                              style: PsgText.body(
                                15,
                                color: PsgColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
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

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  complaint.title,
                  style: PsgText.headline(
                    16,
                    weight: FontWeight.w800,
                    color: PsgColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _statusChip(complaint.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            complaint.description,
            style: PsgText.body(13, color: PsgColors.onSurface),
          ),
          const SizedBox(height: 12),
          Text(
            'Submitted by: ${complaint.userId} • $createdLabel',
            style: PsgText.body(11, color: PsgColors.onSurfaceVariant),
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
                          if (status == null || status == complaint.status) {
                            return;
                          }
                          onStatusChanged(status);
                        },
                ),
              ),
              if (isUpdating) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: PsgColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(ComplaintStatus status) {
    final color = switch (status) {
      ComplaintStatus.pending => Colors.amber,
      ComplaintStatus.inProgress => PsgColors.secondary,
      ComplaintStatus.resolved => Colors.green,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: PsgText.label(9, color: color, letterSpacing: 0.7),
      ),
    );
  }
}
