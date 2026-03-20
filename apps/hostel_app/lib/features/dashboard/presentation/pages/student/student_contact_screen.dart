import 'package:flutter/material.dart';

class StudentContactScreen extends StatelessWidget {
  const StudentContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = [
      const _Contact('Hostel Office', '0422-4344000', Icons.home_work_rounded, isPhone: true),
      const _Contact('Chief Warden', '0422-4344001', Icons.person_rounded, isPhone: true),
      const _Contact('Security', '0422-4344002', Icons.security_rounded, isPhone: true),
      const _Contact('Mess Supervisor', '0422-4344003', Icons.restaurant_rounded, isPhone: true),
      const _Contact('Medical Room', '0422-4344004', Icons.local_hospital_rounded, isPhone: true),
      const _Contact('Email', 'hostel@psgtech.ac.in', Icons.email_rounded, isPhone: false),
      const _Contact(
        'Address',
        'PSG College of Technology, Avinashi Road, Peelamedu, Coimbatore - 641 004',
        Icons.location_on_rounded,
        isPhone: false,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        foregroundColor: Colors.white,
        title: const Text('Contact Us'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            ...contacts.map((contact) => _buildContactCard(context, contact)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2137),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.support_agent_rounded, color: Color(0xFF009688), size: 36),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PSG Hostel Support',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'We\'re here to help you 24/7',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, _Contact contact) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0D2137).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(contact.icon, color: const Color(0xFF0D2137), size: 22),
        ),
        title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(contact.detail, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        trailing: contact.isPhone
            ? IconButton(
                icon: const Icon(Icons.call_rounded, color: Color(0xFF009688)),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling ${contact.detail}...')),
                ),
              )
            : null,
      ),
    );
  }
}

class _Contact {
  final String name;
  final String detail;
  final IconData icon;
  final bool isPhone;
  const _Contact(this.name, this.detail, this.icon, {required this.isPhone});
}
