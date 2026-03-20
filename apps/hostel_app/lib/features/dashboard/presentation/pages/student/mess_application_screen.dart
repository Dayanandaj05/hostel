import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';
import 'package:hostel_app/features/student/data/student_profile_provider.dart';

class MessApplicationScreen extends StatefulWidget {
  const MessApplicationScreen({super.key});

  @override
  State<MessApplicationScreen> createState() => _MessApplicationScreenState();
}

class _MessApplicationScreenState extends State<MessApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isAgreed = false;
  final _remarksController = TextEditingController();

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate() || !_isAgreed) {
      if (!_isAgreed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please agree to the terms and conditions')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthProviderController>().user;
      final profile = context.read<StudentProfileProvider>();

      if (user == null) throw 'User not authenticated';

      await FirebaseFirestore.instance.collection('mess_applications').add({
        'studentId': user.uid,
        'studentName': profile.displayName,
        'rollNumber': profile.rollNumber,
        'currentMess': profile.messType,
        'requestedMess': 'North Indian',
        'status': 'pending',
        'remarks': _remarksController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text('Application Sent'),
              ],
            ),
            content: const Text(
                'Your request for North Indian mess has been submitted successfully. The warden will review it shortly.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Mess Application'),
        backgroundColor: const Color(0xFF0D2137),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            const Text(
              'Apply for North Indian Mess',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2137)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Switching to North Indian mess will change your monthly billing and meal plan.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _remarksController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Reason for switching (Optional)',
                      hintText: 'e.g. Dietary preference',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    value: _isAgreed,
                    onChanged: (v) => setState(() => _isAgreed = v ?? false),
                    title: const Text(
                      'I understand that this change is subject to approval and fixed for at least one billing cycle.',
                      style: TextStyle(fontSize: 12),
                    ),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: const Color(0xFF009688),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submitApplication,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final profile = context.watch<StudentProfileProvider>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _row('Student', profile.displayName),
          const Divider(height: 24),
          _row('Roll Number', profile.rollNumber),
          const Divider(height: 24),
          _row('Current Mess', profile.messType),
          const Divider(height: 24),
          _row('Proposed Mess', 'North Indian', valueColor: const Color(0xFF009688)),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valueColor ?? const Color(0xFF0D2137))),
      ],
    );
  }
}
