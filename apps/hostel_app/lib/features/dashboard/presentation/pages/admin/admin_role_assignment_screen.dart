import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminRoleAssignmentScreen extends StatefulWidget {
  const AdminRoleAssignmentScreen({super.key});

  @override
  State<AdminRoleAssignmentScreen> createState() =>
      _AdminRoleAssignmentScreenState();
}

class _AdminRoleAssignmentScreenState extends State<AdminRoleAssignmentScreen> {
  final _userIdController = TextEditingController();
  String _selectedRole = 'student';
  bool _saving = false;

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _assignRole() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID is required.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {
          'role': _selectedRole,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Role updated successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update role.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Roles')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Role Assignment',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _userIdController,
                      decoration: const InputDecoration(
                        labelText: 'User Document ID',
                        prefixIcon: Icon(Icons.person_search_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(Icons.security_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'student',
                          child: Text('Student'),
                        ),
                        DropdownMenuItem(
                          value: 'warden',
                          child: Text('Warden'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admin'),
                        ),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _selectedRole = value);
                            },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _assignRole,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.how_to_reg_rounded),
                        label: Text(_saving ? 'Updating...' : 'Assign Role'),
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
  }
}
