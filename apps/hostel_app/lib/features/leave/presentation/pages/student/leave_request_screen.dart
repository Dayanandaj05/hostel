import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../controllers/leave_request_controller.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final initialDate = isStartDate
        ? (_startDate ?? firstDate)
        : (_endDate ?? _startDate ?? firstDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 2),
    );

    if (picked == null) return;

    setState(() {
      if (isStartDate) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit(LeaveRequestController controller) async {
    final auth = AuthProviderController.of(context);
    final userId = auth.user?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please login again.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both start and end dates.')),
      );
      return;
    }

    final success = await controller.submitLeaveRequest(
      userId: userId,
      startDate: _startDate!,
      endDate: _endDate!,
      reason: _reasonController.text,
    );

    if (!mounted) return;

    if (success) {
      _formKey.currentState?.reset();
      _reasonController.clear();
      setState(() {
        _startDate = null;
        _endDate = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.successMessage ?? 'Submitted.')),
      );
    } else if (controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaveRequestController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Apply Leave')),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 640 : 500),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Leave Request Form',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Choose your leave dates and provide a reason.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 20),
                              if (isWide)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _DateField(
                                        label: 'Start Date',
                                        value: _startDate,
                                        onTap: () =>
                                            _pickDate(isStartDate: true),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _DateField(
                                        label: 'End Date',
                                        value: _endDate,
                                        onTap: () =>
                                            _pickDate(isStartDate: false),
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                _DateField(
                                  label: 'Start Date',
                                  value: _startDate,
                                  onTap: () => _pickDate(isStartDate: true),
                                ),
                                const SizedBox(height: 16),
                                _DateField(
                                  label: 'End Date',
                                  value: _endDate,
                                  onTap: () => _pickDate(isStartDate: false),
                                ),
                              ],
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _reasonController,
                                minLines: 3,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  labelText: 'Reason',
                                  hintText: 'Enter reason for leave request',
                                  alignLabelWithHint: true,
                                  prefixIcon: Icon(Icons.edit_note),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a reason';
                                  }
                                  if (value.trim().length < 10) {
                                    return 'Reason should be at least 10 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              if (controller.errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    controller.errorMessage!,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: controller.isSubmitting
                                      ? null
                                      : () => _submit(controller),
                                  icon: controller.isSubmitting
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.send_rounded),
                                  label: Text(
                                    controller.isSubmitting
                                        ? 'Submitting...'
                                        : 'Submit Leave Request',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Select $label'
        : '${value!.day.toString().padLeft(2, '0')}/'
            '${value!.month.toString().padLeft(2, '0')}/'
            '${value!.year}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(text),
      ),
    );
  }
}
