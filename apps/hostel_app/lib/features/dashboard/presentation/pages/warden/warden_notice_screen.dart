import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hostel_app/core/design/psg_design_system.dart';
import 'package:intl/intl.dart';

class WardenNoticeScreen extends StatefulWidget {
  const WardenNoticeScreen({super.key});

  @override
  State<WardenNoticeScreen> createState() => _WardenNoticeScreenState();
}

class _WardenNoticeScreenState extends State<WardenNoticeScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _showPostNoticeSheet() {
    _titleController.clear();
    _bodyController.clear();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: GlassCard(
                borderRadius: 32,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Post Warden Notice', style: PsgText.headline(22, color: PsgColors.primary)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _titleController,
                      style: PsgText.body(14, color: PsgColors.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: PsgText.body(14, color: PsgColors.onSurfaceVariant),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: PsgColors.primary),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bodyController,
                      style: PsgText.body(14, color: PsgColors.onSurface),
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Body',
                        labelStyle: PsgText.body(14, color: PsgColors.onSurfaceVariant),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: PsgColors.primary),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    PsgFilledButton(
                      label: 'Post Notice',
                      loading: _isPosting,
                      onPressed: () async {
                        final title = _titleController.text.trim();
                        final body = _bodyController.text.trim();
                        if (title.isEmpty || body.isEmpty) return;

                        setSheetState(() => _isPosting = true);
                        try {
                          await FirebaseFirestore.instance.collection('notices').add({
                            'title': title,
                            'body': body,
                            'createdBy': FirebaseAuth.instance.currentUser?.uid,
                            'createdByRole': 'warden',
                            'isActive': true,
                            'audienceRoles': ['student', 'warden'],
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Notice posted successfully')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to post: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setSheetState(() => _isPosting = false);
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
            onPressed: () => context.canPop() ? context.pop() : context.go('/warden'),
          ),
          title: 'Notices',
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: PsgColors.primary,
          foregroundColor: Colors.white,
          onPressed: _showPostNoticeSheet,
          icon: const Icon(Icons.add_rounded),
          label: Text('Post Notice', style: PsgText.label(14, color: Colors.white)),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notices')
              .where('isActive', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: PsgColors.primary));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Failed to load notices.', style: PsgText.body(14, color: PsgColors.error)));
            }
            
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.campaign_outlined, size: 60, color: PsgColors.outline),
                    const SizedBox(height: 16),
                    Text('No active notices', style: PsgText.label(16, color: PsgColors.onSurfaceVariant)),
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
                          children: [
                            const Icon(Icons.campaign_rounded, color: PsgColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(title, style: PsgText.headline(16, color: PsgColors.onSurface)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
