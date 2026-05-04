import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../../app/app_routes.dart';
import '../../../../../core/design/psg_design_system.dart';
import '../../../../../core/widgets/static_nav_bar.dart';
import '../../../../student/data/student_profile_provider.dart';

class StudentRoomScreen extends StatelessWidget {
  const StudentRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<StudentProfileProvider>();

    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          title: 'My Room',
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: PsgColors.primary,
              size: 20,
            ),
            onPressed: () => context.go(AppRoutes.studentHome),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_rounded, color: PsgColors.primary),
              onPressed: () => context.go(AppRoutes.studentHome),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 88,
            16,
            StaticNavBar.reservedBottomPadding(context) + 16,
          ),
          children: [
            GlassCard(
              child: Column(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: PsgColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.meeting_room_rounded,
                      color: PsgColors.primary,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.roomNumber,
                    style: PsgText.headline(30, color: PsgColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: PsgColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      profile.roomType,
                      style: PsgText.label(10, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
                'Room Information',
                [
                  _RoomDetail(
                    'Room Number',
                    profile.roomNumber,
                    Icons.meeting_room_rounded,
                    copyable: true,
                  ),
                  _RoomDetail('Room Type', profile.roomType, Icons.bed_rounded),
                  _RoomDetail('Floor', profile.floor, Icons.layers_rounded),
                  _RoomDetail(
                      'Block', profile.blockName, Icons.apartment_rounded),
                  _RoomDetail('Hostel', profile.hostelName, Icons.home_rounded),
                ],
                context),
            const SizedBox(height: 12),
            _sectionCard(
                'Joining Details',
                [
                  _RoomDetail(
                      'Joining Date', profile.joiningDate, Icons.event_rounded),
                  _RoomDetail('Student Name', profile.displayName,
                      Icons.person_rounded),
                  _RoomDetail(
                    'Roll Number',
                    profile.rollNumber,
                    Icons.badge_rounded,
                    copyable: true,
                  ),
                ],
                context),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.rule_rounded,
                        color: PsgColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Room Guidelines',
                        style: PsgText.headline(
                          16,
                          weight: FontWeight.w800,
                          color: PsgColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...[
                    'Lights off by 11:00 PM on weekdays',
                    'No guests allowed inside the room',
                    'Keep the room clean and tidy at all times',
                    'Report any damage to the warden immediately',
                    'Ragging in any form is strictly prohibited',
                  ].map(
                    (rule) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 7),
                            child: Icon(
                              Icons.circle,
                              size: 6,
                              color: PsgColors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rule,
                              style: PsgText.body(
                                13,
                                color: PsgColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
      String title, List<_RoomDetail> details, BuildContext context) {
    return GlassCard(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: PsgText.headline(16,
                weight: FontWeight.w800, color: PsgColors.onSurface)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < details.length; i++) ...[
                _buildDetailRow(details[i], context),
                if (i < details.length - 1)
                  Divider(
                    height: 1,
                    color: PsgColors.outline.withValues(alpha: 0.15),
                  ),
              ],
            ],
          ),
        ),
      ],
    ));
  }

  Widget _buildDetailRow(_RoomDetail detail, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(detail.icon, size: 18, color: PsgColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.label,
                    style: PsgText.body(11, color: PsgColors.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(detail.value,
                    style: PsgText.label(13, color: PsgColors.onSurface)),
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
                  size: 16, color: PsgColors.onSurfaceVariant),
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
