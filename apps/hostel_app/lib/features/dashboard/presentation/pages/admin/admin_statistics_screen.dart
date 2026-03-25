import 'package:flutter/material.dart';
import 'package:hostel_app/services/mock/mock_service.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  late Future<Map<String, int>> _future;

  @override
  void initState() {
    super.initState();
    _future = MockService.getAdminMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: FutureBuilder<Map<String, int>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load statistics'));
          }
          final m = snapshot.data ?? const <String, int>{};
          return ListView(
            children: [
              ListTile(
                title: const Text('Total Students'),
                trailing: Text('${m['totalStudents'] ?? 0}'),
              ),
              ListTile(
                title: const Text('Total Rooms'),
                trailing: Text('${m['totalRooms'] ?? 0}'),
              ),
              ListTile(
                title: const Text('Pending Leaves'),
                trailing: Text('${m['pendingLeaves'] ?? 0}'),
              ),
              ListTile(
                title: const Text('Open Complaints'),
                trailing: Text('${m['openComplaints'] ?? 0}'),
              ),
            ],
          );
        },
      ),
    );
  }
}
