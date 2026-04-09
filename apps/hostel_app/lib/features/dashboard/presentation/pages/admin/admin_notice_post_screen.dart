import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hostel_app/core/design/psg_design_system.dart';
import 'package:intl/intl.dart';

class AdminNoticePostScreen extends StatefulWidget {
  const AdminNoticePostScreen({super.key});

  @override
  State<AdminNoticePostScreen> createState() => _AdminNoticePostScreenState();
}

class _AdminNoticePostScreenState extends State<AdminNoticePostScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isPosting = false;
  
  bool _studentChecked = true;
  bool _wardenChecked = true;
  bool _adminChecked = true;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _postNotice() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and body required')));
      return;
    }
    
    final selectedRoles = <String>[];
    if (_studentChecked) selectedRoles.add('student');
    if (_wardenChecked) selectedRoles.add('warden');
    if (_adminChecked) selectedRoles.add('admin');
    
    if (selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one audience')));
      return;
    }

    setState(() => _isPosting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('notices').add({
        'title': title,
        'body': body,
        'createdBy': uid,
        'createdByRole': 'admin',
        'isActive': true,
        'audienceRoles': selectedRoles,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _titleController.clear();
        _bodyController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice posted successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _deleteNotice(DocumentReference docRef) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PsgColors.background,
        title: Text('Delete Notice?', style: PsgText.headline(18, color: PsgColors.error)),
        content: Text('This action cannot be undone.', style: PsgText.body(14, color: PsgColors.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: PsgText.label(14, color: PsgColors.outline)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PsgColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await docRef.delete();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Widget _buildPostForm() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Post New Notice', style: PsgText.headline(18, color: PsgColors.primary)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            style: PsgText.body(14, color: PsgColors.onSurface),
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: PsgText.body(14, color: PsgColors.onSurfaceVariant),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: PsgColors.primary), borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            maxLines: 3,
            style: PsgText.body(14, color: PsgColors.onSurface),
            decoration: InputDecoration(
              labelText: 'Body',
              labelStyle: PsgText.body(14, color: PsgColors.onSurfaceVariant),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: PsgColors.primary), borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Audience', style: PsgText.label(14, color: PsgColors.onSurfaceVariant)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _studentChecked,
                    activeColor: PsgColors.primary,
                    onChanged: (val) => setState(() => _studentChecked = val ?? false),
                  ),
                  Text('Student', style: PsgText.body(12, color: PsgColors.onSurface)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _wardenChecked,
                    activeColor: PsgColors.primary,
                    onChanged: (val) => setState(() => _wardenChecked = val ?? false),
                  ),
                  Text('Warden', style: PsgText.body(12, color: PsgColors.onSurface)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _adminChecked,
                    activeColor: PsgColors.primary,
                    onChanged: (val) => setState(() => _adminChecked = val ?? false),
                  ),
                  Text('Admin', style: PsgText.body(12, color: PsgColors.onSurface)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          PsgFilledButton(
            label: 'Publish Notice',
            loading: _isPosting,
            onPressed: _postNotice,
          ),
        ],
      ),
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
          title: 'Notices & Announcements',
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                  child: Column(
                    children: [
                      _buildPostForm(),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Icon(Icons.history_rounded, color: PsgColors.onSurfaceVariant, size: 20),
                          const SizedBox(width: 8),
                          Text('Recent Notices', style: PsgText.headline(18, color: PsgColors.onSurface)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('notices')
                            .where('isActive', isEqualTo: true)
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(color: PsgColors.primary),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text('Failed to load notices.', style: PsgText.body(14, color: PsgColors.error)),
                              ),
                            );
                          }
                          
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Column(
                                  children: [
                                    const Icon(Icons.campaign_outlined, size: 60, color: PsgColors.outline),
                                    const SizedBox(height: 16),
                                    Text('No active notices', style: PsgText.label(16, color: PsgColors.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final title = data['title'] ?? 'Untitled';
                              final body = data['body'] ?? '';
                              DateTime? createdAt;
                              if (data['createdAt'] is Timestamp) {
                                createdAt = (data['createdAt'] as Timestamp).toDate();
                              }
                              final dateStr = createdAt != null 
                                  ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
                                  : 'Unknown Date';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                const Icon(Icons.campaign_rounded, color: PsgColors.primary, size: 20),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(title, style: PsgText.headline(16, color: PsgColors.onSurface)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: PsgColors.error, size: 20),
                                            onPressed: () => _deleteNotice(doc.reference),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        body,
                                        style: PsgText.body(14, color: PsgColors.onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(dateStr, style: PsgText.label(11, color: PsgColors.outline)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
