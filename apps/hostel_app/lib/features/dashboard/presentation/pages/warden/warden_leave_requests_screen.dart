import 'package:flutter/material.dart';
import 'package:hostel_app/features/leave/domain/entities/leave_request_model.dart';
import 'package:hostel_app/services/mock/mock_service.dart';

class WardenLeaveRequestsScreen extends StatefulWidget {
  const WardenLeaveRequestsScreen({super.key});

  @override
  State<WardenLeaveRequestsScreen> createState() =>
      _WardenLeaveRequestsScreenState();
}

class _WardenLeaveRequestsScreenState extends State<WardenLeaveRequestsScreen> {
  late Future<List<LeaveRequestModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = MockService.watchPendingLeaves().first;
  }

  Future<void> _update(String id, LeaveRequestStatus status) async {
    await MockService.updateLeaveStatus(id, status);
    setState(() => _future = MockService.watchPendingLeaves().first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Requests')),
      body: FutureBuilder<List<LeaveRequestModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load requests'));
          }
          final requests = snapshot.data ?? const <LeaveRequestModel>[];
          if (requests.isEmpty) {
            return const Center(child: Text('No data available'));
          }
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final r = requests[index];
              return ListTile(
                title: Text(r.reason),
                subtitle: Text(
                  '${r.startDate.toLocal()} - ${r.endDate.toLocal()}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () =>
                          _update(r.id ?? '', LeaveRequestStatus.rejected),
                      child: const Text('Reject'),
                    ),
                    TextButton(
                      onPressed: () =>
                          _update(r.id ?? '', LeaveRequestStatus.approved),
                      child: const Text('Approve'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
