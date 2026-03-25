import 'package:flutter/material.dart';
import 'package:hostel_app/services/mock/mock_data.dart';

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: ListView.builder(
        itemCount: MockData.users.length,
        itemBuilder: (context, i) {
          final u = MockData.users[i];
          return ListTile(
            title: Text(u.name),
            subtitle: Text(u.email),
            trailing: Text(u.role.name),
          );
        },
      ),
    );
  }
}
