import 'package:flutter/material.dart';
import 'package:hostel_app/services/mock/mock_service.dart';

class AdminNoticePostScreen extends StatefulWidget {
  const AdminNoticePostScreen({super.key});

  @override
  State<AdminNoticePostScreen> createState() => _AdminNoticePostScreenState();
}

class _AdminNoticePostScreenState extends State<AdminNoticePostScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await MockService.addNotice({
      'title': _title.text.trim(),
      'body': _body.text.trim(),
      'createdBy': 'admin-1',
      'isActive': true,
      'audienceRoles': ['student', 'warden', 'admin'],
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Notice posted')));
    _title.clear();
    _body.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Notice')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(
                controller: _body,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Body')),
            const SizedBox(height: 12),
            FilledButton(onPressed: _submit, child: const Text('Post')),
          ],
        ),
      ),
    );
  }
}
