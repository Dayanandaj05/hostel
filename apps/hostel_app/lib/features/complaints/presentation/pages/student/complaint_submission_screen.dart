import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../controllers/complaint_controller.dart';

class ComplaintSubmissionScreen extends StatefulWidget {
  const ComplaintSubmissionScreen({super.key});

  @override
  State<ComplaintSubmissionScreen> createState() =>
      _ComplaintSubmissionScreenState();
}

class _ComplaintSubmissionScreenState extends State<ComplaintSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit(ComplaintController controller) async {
    final auth = AuthProviderController.of(context);
    final userId = auth.user?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please login again.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final success = await controller.submitComplaint(
      userId: userId,
      title: _titleController.text,
      description: _descriptionController.text,
    );

    if (!mounted) return;

    if (success) {
      _formKey.currentState?.reset();
      _titleController.clear();
      _descriptionController.clear();
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
    return Consumer<ComplaintController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Submit Complaint')),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
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
                            'Complaint Form',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tell us what issue you are facing.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              hintText: 'Short summary of the complaint',
                              prefixIcon: Icon(Icons.title),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a title';
                              }
                              if (value.trim().length < 4) {
                                return 'Title should be at least 4 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            minLines: 4,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'Describe the issue in detail',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.description),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a description';
                              }
                              if (value.trim().length < 10) {
                                return 'Description should be at least 10 characters';
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
                                  color: Theme.of(context).colorScheme.error,
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
                                    : 'Submit Complaint',
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
          ),
        );
      },
    );
  }
}
