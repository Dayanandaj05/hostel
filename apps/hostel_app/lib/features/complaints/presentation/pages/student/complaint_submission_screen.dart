import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hostel_app/app/app_routes.dart';
import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';
import 'package:hostel_app/features/complaints/domain/entities/complaint_model.dart';
import 'package:hostel_app/features/complaints/presentation/controllers/complaint_controller.dart';

class ComplaintSubmissionScreen extends StatefulWidget {
  const ComplaintSubmissionScreen({super.key});

  @override
  State<ComplaintSubmissionScreen> createState() =>
      _ComplaintSubmissionScreenState();
}

class _ComplaintSubmissionScreenState extends State<ComplaintSubmissionScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ComplaintController>().watchComplaints();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uid = AuthProviderController.of(context).user?.uid;
    if (uid == null) return;
    final controller = context.read<ComplaintController>();
    final ok = await controller.submitComplaint(
      userId: uid,
      title: _titleController.text,
      description: _descriptionController.text,
    );
    if (!mounted) return;
    if (ok) {
      _titleController.clear();
      _descriptionController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Complaint submitted')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage ?? 'Failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthProviderController.of(context).user?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.studentHome),
        ),
      ),
      body: Consumer<ComplaintController>(
        builder: (context, controller, _) {
          final mine = controller.complaints
              .where((c) => c.userId == uid)
              .toList(growable: false);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: controller.isSubmitting ? null : _submit,
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: mine.isEmpty
                    ? const Center(child: Text('No data available'))
                    : ListView.builder(
                        itemCount: mine.length,
                        itemBuilder: (context, index) {
                          final c = mine[index];
                          return ListTile(
                            title: Text(c.title),
                            subtitle: Text(c.description),
                            trailing: Text(c.status.label),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
