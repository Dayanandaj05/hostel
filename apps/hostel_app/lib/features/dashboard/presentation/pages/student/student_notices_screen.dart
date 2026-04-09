import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hostel_app/app/app_routes.dart';
import 'package:hostel_app/core/design/psg_design_system.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentNoticesScreen extends StatefulWidget {
  const StudentNoticesScreen({super.key});

  @override
  State<StudentNoticesScreen> createState() => _StudentNoticesScreenState();
}

class _StudentNoticesScreenState extends State<StudentNoticesScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(
      () => setState(() => _scrollOffset = _scrollController.offset),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          scrollOffset: _scrollOffset,
          title: 'Notices',
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: PsgColors.primary,
              size: 20,
            ),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.studentHome),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notices')
              .where('isActive', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Unable to load notices.'));
            }
            final notices = snapshot.data?.docs ?? [];
            if (notices.isEmpty) {
              return const Center(child: Text('No data available'));
            }
            return ListView.separated(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 88,
                bottom: 40,
                left: 20,
                right: 20,
              ),
              itemCount: notices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final n = notices[index].data() as Map<String, dynamic>;
                final createdAt = (n['createdAt'] as Timestamp?)?.toDate();
                return GlassCard(
                  borderRadius: 16,
                  child: ListTile(
                    title: Text(
                      n['title']?.toString() ?? 'Notice',
                      style: PsgText.label(14, color: PsgColors.primary),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(n['body']?.toString() ?? ''),
                    ),
                    trailing: Text(
                      createdAt == null
                          ? ''
                          : '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                      style: PsgText.body(
                        11,
                        color: PsgColors.onSurfaceVariant,
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
