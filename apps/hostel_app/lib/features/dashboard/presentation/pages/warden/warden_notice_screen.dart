import 'package:flutter/material.dart';
import 'package:hostel_app/services/mock/mock_service.dart';

class WardenNoticeScreen extends StatefulWidget {
  const WardenNoticeScreen({super.key});

  @override
  State<WardenNoticeScreen> createState() => _WardenNoticeScreenState();
}

class _WardenNoticeScreenState extends State<WardenNoticeScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = MockService.watchNotices().first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Warden Notices')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load notices'));
          }
          final notices = snapshot.data ?? const <Map<String, dynamic>>[];
          if (notices.isEmpty) {
            return const Center(child: Text('No data available'));
          }
          return ListView(
            children: notices
                .map(
                  (n) => ListTile(
                    title: Text('${n['title']}'),
                    subtitle: Text('${n['body']}'),
                  ),
                )
                .toList(growable: false),
          );
        },
      ),
    );
  }
}
