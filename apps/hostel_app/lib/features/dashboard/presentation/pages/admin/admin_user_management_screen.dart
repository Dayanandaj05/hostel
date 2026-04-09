import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hostel_app/core/design/psg_design_system.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  void _showUserForm([DocumentSnapshot? userDoc]) {
    final isEditing = userDoc != null;
    final data = isEditing ? userDoc.data() as Map<String, dynamic> : null;
    
    final nameCtrl = TextEditingController(text: data?['name'] ?? '');
    final emailCtrl = TextEditingController(text: data?['email'] ?? '');
    final rollCtrl = TextEditingController(text: data?['rollNumber'] ?? '');
    final roomCtrl = TextEditingController(text: data?['roomNumber'] ?? '');
    String selectedRole = data?['role'] ?? 'student';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isStudent = selectedRole == 'student';
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: GlassCard(
                borderRadius: 32,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(isEditing ? 'Edit User' : 'Add New User', style: PsgText.headline(22, color: PsgColors.primary)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameCtrl,
                      style: PsgText.body(14, color: PsgColors.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: PsgText.body(14, color: PsgColors.onSurfaceVariant),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: PsgColors.primary), borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailCtrl,
                      style: PsgText.body(14, color: PsgColors.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: PsgText.body(14, color: PsgColors.onSurfaceVariant),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: PsgColors.primary), borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      dropdownColor: PsgColors.background,
                      style: PsgText.body(14, color: PsgColors.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Role',
                        labelStyle: PsgText.body(14, color: PsgColors.onSurfaceVariant),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: PsgColors.primary), borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['student', 'warden', 'admin'].map((r) {
                        return DropdownMenuItem(value: r, child: Text(r.toUpperCase()));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedRole = val);
                      },
                    ),
                    if (isStudent) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: rollCtrl,
                        style: PsgText.body(14, color: PsgColors.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Roll Number',
                          labelStyle: PsgText.body(14, color: PsgColors.onSurfaceVariant),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: PsgColors.primary), borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: roomCtrl,
                        style: PsgText.body(14, color: PsgColors.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Room Number (optional)',
                          labelStyle: PsgText.body(14, color: PsgColors.onSurfaceVariant),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: PsgColors.primary), borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    PsgFilledButton(
                      label: 'Save User',
                      loading: isSaving,
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        if (name.isEmpty || email.isEmpty) return;

                        setSheetState(() => isSaving = true);
                        try {
                          final payload = <String, dynamic>{
                            'name': name,
                            'email': email,
                            'role': selectedRole,
                            if (isStudent) 'rollNumber': rollCtrl.text.trim(),
                            if (isStudent) 'roomNumber': roomCtrl.text.trim(),
                          };

                          if (isEditing) {
                            payload['updatedAt'] = FieldValue.serverTimestamp();
                            await userDoc.reference.update(payload);
                          } else {
                            payload['createdAt'] = FieldValue.serverTimestamp();
                            await FirebaseFirestore.instance.collection('users').add(payload);
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User saved successfully')));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        } finally {
                          if (context.mounted) setSheetState(() => isSaving = false);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: PsgColors.primary, size: 20),
            onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
          ),
          title: 'User Management',
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: PsgColors.primary,
          foregroundColor: Colors.white,
          onPressed: () => _showUserForm(),
          child: const Icon(Icons.person_add_rounded),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: PsgColors.primary));
            if (snapshot.hasError) return Center(child: Text('Error loading users', style: PsgText.body(14, color: PsgColors.error)));
            
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.group_outlined, size: 60, color: PsgColors.outline),
                    const SizedBox(height: 16),
                    Text('No users found', style: PsgText.label(16, color: PsgColors.onSurfaceVariant)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 100, 24, 120),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'] ?? 'Unknown User';
                final email = data['email'] ?? 'No email';
                final role = data['role'] ?? 'user';
                final rollNumber = data['rollNumber'] ?? '';
                final roomNumber = data['roomNumber'] ?? '';

                Color roleColor;
                if (role == 'admin') {
                  roleColor = PsgColors.error;
                } else if (role == 'warden') {
                  roleColor = PsgColors.amber;
                } else {
                  roleColor = Colors.teal;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _showUserForm(doc),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: roleColor.withValues(alpha: 0.15),
                            child: Icon(Icons.person, color: roleColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: PsgText.headline(16, color: PsgColors.onSurface)),
                                Text(email, style: PsgText.body(12, color: PsgColors.onSurfaceVariant)),
                                if (role == 'student') ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Roll: ${rollNumber.isEmpty ? 'N/A' : rollNumber} | Room: ${roomNumber.isEmpty ? '?' : roomNumber}',
                                    style: PsgText.label(11, color: PsgColors.onSurfaceVariant),
                                  ),
                                ]
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(role.toUpperCase(), style: PsgText.label(10, color: roleColor)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
