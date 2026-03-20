import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';

class WardenNoticeScreen extends StatefulWidget {
  const WardenNoticeScreen({super.key});

  @override
  State<WardenNoticeScreen> createState() => _WardenNoticeScreenState();
}

class _WardenNoticeScreenState extends State<WardenNoticeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _postNotice() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _posting = true);

    final uid = AuthProviderController.of(context).user?.uid;
    try {
      await FirebaseFirestore.instance.collection('notices').add({
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'createdBy': uid,
        'isActive': true,
        'audienceRoles': ['student', 'warden'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _formKey.currentState?.reset();
      _titleController.clear();
      _bodyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notice posted successfully.')),
      );
      _tabController.animateTo(1);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post notice.')),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        foregroundColor: Colors.white,
        title: const Text('Notices'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: const Color(0xFF009688),
          tabs: const [
            Tab(text: 'Post Notice'),
            Tab(text: 'All Notices'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostTab(),
          _buildListTab(),
        ],
      ),
    );
  }

  Widget _buildPostTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Hostel Notice',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D2137),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Notice Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bodyController,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Notice Content',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.article_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Content is required';
                        if (v.trim().length < 10) return 'Content too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _posting ? null : _postNotice,
                        icon: _posting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.campaign_rounded),
                        label: Text(_posting ? 'Posting...' : 'Post Notice'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0D2137),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
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
    );
  }

  Widget _buildListTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notices')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('No notices yet.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final ts = data['createdAt'] as Timestamp?;
            final isActive = data['isActive'] as bool? ?? true;
            String date = '';
            if (ts != null) {
              final dt = ts.toDate();
              date =
                  '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
            }

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF0D2137),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 11,
                              color: isActive ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((data['body'] as String? ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        data['body'] as String,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          date,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('notices')
                                .doc(docs[i].id)
                                .update({'isActive': !isActive});
                          },
                          icon: Icon(
                            isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 16,
                          ),
                          label: Text(isActive ? 'Deactivate' : 'Activate', style: const TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: isActive ? Colors.grey : const Color(0xFF009688),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
