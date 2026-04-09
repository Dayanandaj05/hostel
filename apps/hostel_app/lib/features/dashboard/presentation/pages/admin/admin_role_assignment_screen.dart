import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hostel_app/core/design/psg_design_system.dart';

class AdminRoleAssignmentScreen extends StatelessWidget {
  const AdminRoleAssignmentScreen({super.key});

  Future<void> _changeRole(BuildContext context, DocumentSnapshot doc, String newRole) async {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'User';
    final currentRole = data['role'] ?? 'student';
    
    if (currentRole == newRole) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PsgColors.background,
        title: Text('Change Role?', style: PsgText.headline(18, color: PsgColors.primary)),
        content: Text('Are you sure you want to change $name\'s role to $newRole?', style: PsgText.body(14, color: PsgColors.onSurface)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: PsgText.label(14, color: PsgColors.outline))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PsgColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      try {
        await doc.reference.update({'role': newRole, 'updatedAt': FieldValue.serverTimestamp()});
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Role updated for $name. Note: Ask user to sign out and back in for role changes to take effect'),
            duration: const Duration(seconds: 4),
          ));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
        }
      }
    }
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
          title: 'Role Assignments',
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: PsgColors.primary));
            if (snapshot.hasError) return Center(child: Text('Error loading users', style: PsgText.body(14, color: PsgColors.error)));
            
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.security_rounded, size: 60, color: PsgColors.outline),
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
                final role = data['role'] ?? 'student';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: PsgText.headline(16, color: PsgColors.onSurface)),
                              Text(email, style: PsgText.body(12, color: PsgColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: role,
                              dropdownColor: PsgColors.background,
                              icon: const Icon(Icons.arrow_drop_down_rounded, color: PsgColors.primary),
                              style: PsgText.label(14, color: PsgColors.primary),
                              items: ['student', 'warden', 'admin'].map((r) {
                                return DropdownMenuItem(value: r, child: Text(r.toUpperCase()));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) _changeRole(context, doc, val);
                              },
                            ),
                          ),
                        ),
                      ],
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
