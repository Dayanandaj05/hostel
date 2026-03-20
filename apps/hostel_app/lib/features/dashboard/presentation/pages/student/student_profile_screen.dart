import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';
import 'package:hostel_app/features/student/data/student_profile_provider.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = AuthProviderController.of(context).user?.uid;
      if (uid != null) {
        context.read<StudentProfileProvider>().startWatching(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        foregroundColor: Colors.white,
        title: const Text('My Profile'),
        elevation: 0,
      ),
      body: Consumer<StudentProfileProvider>(
        builder: (context, profile, _) {
          if (profile.isLoading && profile.profileData == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (profile.error != null) {
            return Center(child: Text(profile.error!));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(profile),
                Container(
                  color: const Color(0xFFF5F6FA),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSection('Academic Information', [
                        _InfoRow('Programme', profile.programme, Icons.school_rounded, copyable: false),
                        _InfoRow('Year of Study', profile.yearOfStudy, Icons.calendar_today_rounded, copyable: false),
                        _InfoRow('Roll Number', profile.rollNumber, Icons.badge_rounded, copyable: true),
                        _InfoRow('Email', profile.email, Icons.email_rounded, copyable: true),
                      ]),
                      _buildSection('Hostel Information', [
                        _InfoRow('Hostel', profile.hostelName, Icons.home_rounded, copyable: false),
                        _InfoRow('Block', profile.blockName, Icons.apartment_rounded, copyable: false),
                        _InfoRow('Room Number', profile.roomNumber, Icons.meeting_room_rounded, copyable: true),
                        _InfoRow('Room Type', profile.roomType, Icons.bed_rounded, copyable: false),
                        _InfoRow('Floor', profile.floor, Icons.layers_rounded, copyable: false),
                        _InfoRow('Joining Date', profile.joiningDate, Icons.event_rounded, copyable: false),
                      ]),
                      _buildSection('Contact Details', [
                        _InfoRow('Phone', profile.contactPhone, Icons.phone_rounded, copyable: true),
                        _InfoRow('Father Name', profile.fatherName, Icons.person_rounded, copyable: false),
                        _InfoRow('Primary Mobile', profile.primaryMobile, Icons.phone_android_rounded, copyable: true),
                        _InfoRow('Secondary Mobile', profile.secondaryMobile, Icons.phone_android_rounded, copyable: true),
                      ]),
                      _buildSection('Address', [
                        _InfoRow('Address', profile.address, Icons.location_on_rounded, copyable: false),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(StudentProfileProvider profile) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0D2137),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF009688),
            child: Text(
              profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : 'S',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.displayName,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            profile.rollNumber,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              profile.programme,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<_InfoRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            bold: true,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D2137),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          color: Colors.white,
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                _buildRow(rows[i]),
                if (i < rows.length - 1) Divider(height: 1, color: Colors.grey.shade100),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRow(_InfoRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(row.icon, size: 18, color: const Color(0xFF009688)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  row.value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (row.copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: row.value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${row.label} copied'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Icon(Icons.copy_rounded, size: 16, color: Colors.grey.shade400),
            ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  final IconData icon;
  final bool copyable;
  const _InfoRow(this.label, this.value, this.icon, {this.copyable = false});
}
