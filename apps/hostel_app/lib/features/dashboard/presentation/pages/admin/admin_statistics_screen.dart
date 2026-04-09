import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    _future = _fetchStats();
  }

  Future<Map<String, int>> _fetchStats() async {
    try {
      final db = FirebaseFirestore.instance;
      
      final studentsSnap = await db.collection('users').where('role', isEqualTo: 'student').get();
      final totalStudents = studentsSnap.size;
      final totalRooms = studentsSnap.docs
          .map((d) => (d.data())['roomId'] as String?)
          .where((r) => r != null && r.isNotEmpty)
          .toSet()
          .length;

      final lqSnap = await db.collection('leave_requests').where('status', isEqualTo: 'pending').count().get();
      final pendingLeaves = lqSnap.count ?? 0;

      final cmSnap = await db.collection('complaints').where('status', isEqualTo: 'open').count().get();
      final openComplaints = cmSnap.count ?? 0;

      return {
        'totalStudents': totalStudents,
        'totalRooms': totalRooms,
        'pendingLeaves': pendingLeaves,
        'openComplaints': openComplaints,
      };
    } catch (_) {
      return {};
    }
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
