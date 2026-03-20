import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../../../../app/app_routes.dart';
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
    final auth = AuthProviderController.of(context);
    final userId = auth.user?.uid;

    return Consumer<ComplaintController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D2137),
            foregroundColor: Colors.white,
            title: const Text('My Complaints'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.go(AppRoutes.studentHome),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.home_rounded),
                onPressed: () => context.go(AppRoutes.studentHome),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showComplaintForm(context, controller),
            backgroundColor: const Color(0xFF0D2137),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: userId == null
              ? const Center(child: Text('User not found'))
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('complaints')
                      .where('userId', isEqualTo: userId)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text('No complaints submitted yet', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => _showComplaintForm(context, controller),
                              child: const Text('SUBMIT FIRST COMPLAINT'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final status = data['status'] ?? 'pending';
                        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                        final remarks = data['wardenRemarks'] as String?;

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
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
                                    Expanded(
                                      child: Text(
                                        data['title'] ?? 'No Title',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    _buildStatusChip(status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  data['description'] ?? '',
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(
                                      createdAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt) : 'Just now',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                    ),
                                  ],
                                ),
                                if (remarks != null && remarks.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Warden Remarks:',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                                        const SizedBox(height: 4),
                                        Text(remarks, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'resolved':
        color = Colors.green;
        label = 'RESOLVED';
      case 'in_progress':
        color = Colors.blue;
        label = 'IN PROGRESS';
      default:
        color = Colors.amber.shade700;
        label = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  void _showComplaintForm(BuildContext context, ComplaintController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Complaint', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (val) => (val?.isEmpty ?? true) ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  validator: (val) => (val?.isEmpty ?? true) ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: controller.isSubmitting ? null : () => _submitAndClose(context, controller),
                    child: controller.isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('SUBMIT COMPLAINT'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitAndClose(BuildContext context, ComplaintController controller) async {
    await _submit(controller);
    if (context.mounted && controller.errorMessage == null) {
      Navigator.pop(context);
    }
  }
}
