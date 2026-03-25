import 'package:flutter/material.dart';
import 'package:hostel_app/services/mock/mock_data.dart';

class WardenMessApplicationsScreen extends StatelessWidget {
  const WardenMessApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = MockData.messApplications;
    return Scaffold(
      appBar: AppBar(title: const Text('Mess Applications')),
      body: items.isEmpty
          ? const Center(child: Text('No data available'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final a = items[i];
                return ListTile(
                  title: Text(a['studentName']?.toString() ?? 'Student'),
                  subtitle:
                      Text('${a['currentMess']} -> ${a['requestedMess']}'),
                  trailing: Text(a['status']?.toString() ?? 'pending'),
                );
              },
            ),
    );
  }
}
