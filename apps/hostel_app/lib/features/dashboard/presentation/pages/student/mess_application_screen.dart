import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';
import 'package:hostel_app/features/student/data/student_profile_provider.dart';
import 'package:hostel_app/services/mock/mock_data.dart';

class MessApplicationScreen extends StatefulWidget {
  const MessApplicationScreen({super.key});

  @override
  State<MessApplicationScreen> createState() => _MessApplicationScreenState();
}

class _MessApplicationScreenState extends State<MessApplicationScreen> {
  final _remarksController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = context.read<AuthProviderController>().user;
    final profile = context.read<StudentProfileProvider>();
    final remarks = _remarksController.text.trim();

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (user != null) {
      MockData.messApplications.add({
        'studentId': user.uid,
        'studentName': profile.displayName,
        'rollNumber': profile.rollNumber,
        'currentMess': profile.messType,
        'requestedMess': 'North Indian',
        'status': 'pending',
        'remarks': remarks,
      });
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Application submitted')));
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<StudentProfileProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mess Application')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
                title: const Text('Current Mess'),
                trailing: Text(profile.messType)),
            TextField(
                controller: _remarksController,
                decoration:
                    const InputDecoration(labelText: 'Reason (optional)')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}
