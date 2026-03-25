import 'package:flutter/material.dart';
import 'package:hostel_app/services/mock/mock_data.dart';

class AdminRoomAllocationScreen extends StatelessWidget {
  const AdminRoomAllocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room Allocation')),
      body: ListView.builder(
        itemCount: MockData.students.length,
        itemBuilder: (context, i) {
          final s = MockData.students[i];
          return ListTile(
            title: Text(s['name']?.toString() ?? 'Student'),
            trailing: Text(s['roomId']?.toString() ?? '--'),
          );
        },
      ),
    );
  }
}
