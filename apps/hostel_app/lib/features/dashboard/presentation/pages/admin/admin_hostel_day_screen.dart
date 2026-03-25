import 'package:flutter/material.dart';
import 'package:hostel_app/services/mock/mock_data.dart';

class AdminHostelDayScreen extends StatelessWidget {
  const AdminHostelDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = MockData.hostelDaySettings;
    return Scaffold(
      appBar: AppBar(title: const Text('Hostel Day Settings')),
      body: ListView(
        children: [
          ListTile(
              title: const Text('Event Name'),
              subtitle: Text('${settings['eventName']}')),
          ListTile(
              title: const Text('Venue'),
              subtitle: Text('${settings['venue']}')),
          ListTile(
              title: const Text('Registration Open'),
              subtitle: Text('${settings['registrationOpen']}')),
          ListTile(
              title: const Text('Max Visitors'),
              subtitle: Text('${settings['maxVisitorsPerStudent']}')),
        ],
      ),
    );
  }
}
