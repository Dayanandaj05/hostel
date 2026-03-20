import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../../app/app_routes.dart';
import '../../../../student/data/student_profile_provider.dart';

class StudentRoomScreen extends StatelessWidget {
  const StudentRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<StudentProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        foregroundColor: Colors.white,
        title: const Text('My Room'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go(AppRoutes.studentHome),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () => context.go(AppRoutes.studentHome),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Room header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D2137), Color(0xFF1E4080)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF009688), width: 2.5),
                    ),
                    child: const Icon(Icons.meeting_room_rounded,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.roomNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009688),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      profile.roomType,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // Room details
            Container(
              color: const Color(0xFFF5F6FA),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionCard('Room Information', [
                    _RoomDetail('Room Number', profile.roomNumber,
                        Icons.meeting_room_rounded, copyable: true),
                    _RoomDetail('Room Type', profile.roomType,
                        Icons.bed_rounded),
                    _RoomDetail('Floor', profile.floor,
                        Icons.layers_rounded),
                    _RoomDetail('Block', profile.blockName,
                        Icons.apartment_rounded),
                    _RoomDetail('Hostel', profile.hostelName,
                        Icons.home_rounded),
                  ], context),
                  _sectionCard('Joining Details', [
                    _RoomDetail('Joining Date', profile.joiningDate,
                        Icons.event_rounded),
                    _RoomDetail('Student Name', profile.displayName,
                        Icons.person_rounded),
                    _RoomDetail('Roll Number', profile.rollNumber,
                        Icons.badge_rounded, copyable: true),
                  ], context),

                  // Room rules card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D2137).withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF0D2137).withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.rule_rounded,
                                color: Color(0xFF0D2137), size: 20),
                            const SizedBox(width: 8),
                            const Text('Room Guidelines',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0D2137),
                              )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...[
                          'Lights off by 11:00 PM on weekdays',
                          'No guests allowed inside the room',
                          'Keep the room clean and tidy at all times',
                          'Report any damage to the warden immediately',
                          'Ragging in any form is strictly prohibited',
                        ].map((rule) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.circle, size: 6,
                                  color: Color(0xFF009688)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(rule,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  )),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, List<_RoomDetail> details, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D2137),
            fontSize: 15,
          )),
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
              for (int i = 0; i < details.length; i++) ...[
                _buildDetailRow(details[i], context),
                if (i < details.length - 1)
                  Divider(height: 1, color: Colors.grey.shade100),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDetailRow(_RoomDetail detail, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(detail.icon, size: 18, color: const Color(0xFF009688)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(detail.value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (detail.copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: detail.value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${detail.label} copied'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Icon(Icons.copy_rounded,
                  size: 16, color: Colors.grey.shade400),
            ),
        ],
      ),
    );
  }
}

class _RoomDetail {
  final String label;
  final String value;
  final IconData icon;
  final bool copyable;
  const _RoomDetail(this.label, this.value, this.icon, {this.copyable = false});
}
