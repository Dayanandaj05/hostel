import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hostel_app/features/leave/domain/entities/leave_request_model.dart';
import 'package:hostel_app/features/leave/presentation/controllers/leave_request_controller.dart';
import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';
import 'package:hostel_app/core/theme/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Branding & UI Constants
// ─────────────────────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0D2137);
const _kTeal = Color(0xFF009688);

// ─────────────────────────────────────────────────────────────────────────────
// LEAVE REQUEST SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = AuthProviderController.of(context);
      if (auth.user?.uid != null) {
        context.read<LeaveRequestController>().startWatchingHistory(auth.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave'),
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
      ),
      body: Consumer<LeaveRequestController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, controller),
                const SizedBox(height: 16),
                _buildHistorySection(context, controller),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LeaveRequestController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Leave History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _kNavy,
              ),
        ),
        FilledButton.icon(
          onPressed: () => _showApplyLeaveModal(context, controller),
          style: FilledButton.styleFrom(
            backgroundColor: _kTeal,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Apply New Leave'),
        ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context, LeaveRequestController controller) {
    if (controller.isLoadingHistory) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (controller.leaveHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(Icons.history_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No leave history found',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return _buildDesktopTable(context, controller);
        } else {
          return _buildMobileList(context, controller);
        }
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context, LeaveRequestController controller) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(cs.surfaceContainerHighest.withOpacity(0.3)),
          columns: const [
            DataColumn(label: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('From Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('To Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Leave Type', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Reason', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: List.generate(controller.leaveHistory.length, (index) {
            final request = controller.leaveHistory[index];
            return DataRow(cells: [
              DataCell(Text((index + 1).toString())),
              DataCell(Text(_formatDateTime(request.startDate))),
              DataCell(Text(_formatDateTime(request.endDate))),
              DataCell(Text(request.leaveType ?? '--')),
              DataCell(SizedBox(width: 200, child: Text(request.reason, overflow: TextOverflow.ellipsis))),
              DataCell(_StatusChip(status: request.status)),
              DataCell(_CancelButton(
                onPressed: _canCancel(request)
                    ? () => _confirmCancel(context, controller, request.id!)
                    : null,
              )),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, LeaveRequestController controller) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.leaveHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = controller.leaveHistory[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      request.leaveType ?? 'Leave',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    _StatusChip(status: request.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatDateTime(request.startDate)} to ${_formatDateTime(request.endDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(request.reason),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: _CancelButton(
                    onPressed: _canCancel(request)
                        ? () => _confirmCancel(context, controller, request.id!)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d-$m-$y $h:$min';
  }

  bool _canCancel(LeaveRequestModel request) {
    return request.status == LeaveRequestStatus.pending && request.startDate.isAfter(DateTime.now());
  }

  Future<void> _confirmCancel(BuildContext context, LeaveRequestController controller, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Leave'),
        content: const Text('Are you sure you want to cancel this leave request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await controller.cancelLeave(id);
      if (context.mounted && !success && controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
      }
    }
  }

  void _showApplyLeaveModal(BuildContext context, LeaveRequestController controller) {
    showDialog(
      context: context,
      builder: (context) => _ApplyLeaveDialog(controller: controller),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG & COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _ApplyLeaveDialog extends StatefulWidget {
  const _ApplyLeaveDialog({required this.controller});
  final LeaveRequestController controller;

  @override
  State<_ApplyLeaveDialog> createState() => _ApplyLeaveDialogState();
}

class _ApplyLeaveDialogState extends State<_ApplyLeaveDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  String? _leaveType = 'Leave';
  String? _approvalManager = 'Hostel Warden';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day, 0, 0);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
    );
    if (time == null) return;

    setState(() {
      final newDt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (isStart) {
        _startDate = newDt;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(hours: 1));
        }
      } else {
        _endDate = newDt;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Apply New Leave', style: TextStyle(fontWeight: FontWeight.bold, color: _kNavy)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDateTimePicker('From Date', _startDate, () => _pickDateTime(true))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDateTimePicker('To Date', _endDate, () => _pickDateTime(false))),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _leaveType,
                  decoration: const InputDecoration(labelText: 'Leave Type', border: OutlineInputBorder()),
                  items: ['Leave', 'Permission', 'Visiting Home', 'Outing']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _leaveType = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Enter the purpose of your leave',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Reason is required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _approvalManager,
                  decoration: const InputDecoration(labelText: 'Approval Manager', border: OutlineInputBorder()),
                  items: ['Hostel Warden', 'Block Warden', 'Chief Warden']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _approvalManager = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: _kNavy),
          child: const Text('Apply Leave'),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker(String label, DateTime value, VoidCallback onTap) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year;
    final h = (value.hour % 12 == 0 ? 12 : value.hour % 12).toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    final ampm = value.hour >= 12 ? 'PM' : 'AM';

    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text('$d/$m/$y $h:$min $ampm', style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = AuthProviderController.of(context);
    final userId = auth.user?.uid;
    if (userId == null) return;

    final success = await widget.controller.submitLeaveRequest(
      userId: userId,
      startDate: _startDate,
      endDate: _endDate,
      reason: _reasonController.text.trim(),
      leaveType: _leaveType,
      approvalManager: _approvalManager,
    );

    if (mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave applied successfully!')));
    } else if (mounted && widget.controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.controller.errorMessage!)));
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final LeaveRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      LeaveRequestStatus.approved => Colors.green,
      LeaveRequestStatus.rejected => Colors.red,
      LeaveRequestStatus.pending => Colors.amber,
    };

    return Chip(
      label: Text(status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: onPressed == null ? 'Cannot cancel approved or past leave' : 'Cancel leave request',
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: BorderSide(color: onPressed == null ? Colors.grey.shade300 : Colors.red),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          visualDensity: VisualDensity.compact,
        ),
        child: const Text('Cancel Leave', style: TextStyle(fontSize: 11)),
      ),
    );
  }
}
