import 'package:flutter/material.dart';
import 'package:hostel_app/services/mock/mock_data.dart';

class AdminRoleAssignmentScreen extends StatefulWidget {
  const AdminRoleAssignmentScreen({super.key});

  @override
  State<AdminRoleAssignmentScreen> createState() =>
      _AdminRoleAssignmentScreenState();
}

class _AdminRoleAssignmentScreenState extends State<AdminRoleAssignmentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Roles')),
      body: ListView.builder(
        itemCount: MockData.users.length,
        itemBuilder: (context, index) {
          final user = MockData.users[index];
          return ListTile(
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: Text(user.role.name),
          );
        },
      ),
    );
  }
}
