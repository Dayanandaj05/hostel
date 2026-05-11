import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../app/app_routes.dart';
import '../../../../../core/design/psg_design_system.dart';
import '../../../../../core/widgets/static_nav_bar.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../../../student/data/student_profile_provider.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final nextOffset = _scrollController.offset;
      if ((nextOffset - _scrollOffset).abs() < 8) return;
      if (!mounted) return;
      setState(() => _scrollOffset = nextOffset);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = AuthProviderController.of(context).user?.uid;
      if (uid != null) {
        context.read<StudentProfileProvider>().startWatching(uid);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProfileProvider>(
      builder: (context, profile, _) {
        if (profile.isLoading && profile.profileData == null) {
          return const MeshBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (profile.error != null) {
          return MeshBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Text(
                  profile.error!,
                  style: PsgText.body(14, color: PsgColors.error),
                ),
              ),
            ),
          );
        }

        return MeshBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: PsgGlassAppBar(
              scrollOffset: _scrollOffset,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => context.go(AppRoutes.studentHome),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.home_rounded),
                  onPressed: () => context.go(AppRoutes.studentHome),
                ),
                const SizedBox(width: 12),
              ],
            ),
            body: ListView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 88,
                bottom: StaticNavBar.reservedBottomPadding(context) + 20,
                left: 20,
                right: 20,
              ),
              children: [
                // ── Header with avatar
                _buildProfileHeader(profile),
                const SizedBox(height: 28),

                // ── Academic Information
                _buildSection('ACADEMIC INFORMATION', [
                  _SectionRow(
                    'Programme',
                    profile.programme,
                    Icons.school_rounded,
                  ),
                  _SectionRow(
                    'Year of Study',
                    profile.yearOfStudy,
                    Icons.calendar_today_rounded,
                  ),
                  _SectionRow(
                    'Roll Number',
                    profile.rollNumber,
                    Icons.badge_rounded,
                    copyable: true,
                  ),
                  _SectionRow(
                    'Email',
                    profile.email,
                    Icons.email_rounded,
                    copyable: true,
                  ),
                ]),
                const SizedBox(height: 20),

                // ── Hostel Information
                _buildSection('HOSTEL INFORMATION', [
                  _SectionRow(
                    'Hostel',
                    profile.hostelName,
                    Icons.home_rounded,
                  ),
                  _SectionRow(
                    'Block',
                    profile.blockName,
                    Icons.apartment_rounded,
                  ),
                  _SectionRow(
                    'Room Number',
                    profile.roomNumber,
                    Icons.meeting_room_rounded,
                    copyable: true,
                  ),
                  _SectionRow(
                    'Room Type',
                    profile.roomType,
                    Icons.bed_rounded,
                  ),
                  _SectionRow(
                    'Floor',
                    profile.floor,
                    Icons.layers_rounded,
                  ),
                  _SectionRow(
                    'Joining Date',
                    profile.joiningDate,
                    Icons.event_rounded,
                  ),
                ]),
                const SizedBox(height: 20),

                // ── Contact Details
                _buildSection('CONTACT DETAILS', [
                  _SectionRow(
                    'Phone',
                    profile.contactPhone,
                    Icons.phone_rounded,
                    copyable: true,
                  ),
                  _SectionRow(
                    'Father Name',
                    profile.fatherName,
                    Icons.person_rounded,
                  ),
                  _SectionRow(
                    'Primary Mobile',
                    profile.primaryMobile,
                    Icons.phone_android_rounded,
                    copyable: true,
                  ),
                  _SectionRow(
                    'Secondary Mobile',
                    profile.secondaryMobile,
                    Icons.phone_android_rounded,
                    copyable: true,
                  ),
                  _SectionRow(
                    'Blood Group',
                    profile.bloodGroup,
                    Icons.bloodtype_rounded,
                  ),
                ]),
                const SizedBox(height: 20),

                // ── Address
                _buildSection('ADDRESS', [
                  _SectionRow(
                    'Address',
                    profile.address,
                    Icons.location_on_rounded,
                  ),
                ]),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(StudentProfileProvider profile) {
    final initials = profile.displayName.isEmpty
        ? 'S'
        : profile.displayName.split(' ').map((w) => w[0]).join().toUpperCase();

    return Column(
      children: [
        // Avatar
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [PsgColors.primary, PsgColors.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: PsgColors.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: PsgText.headline(
                44,
                weight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Name
        Text(
          profile.displayName,
          style: PsgText.headline(
            28,
            weight: FontWeight.w900,
            color: PsgColors.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Roll Number Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: PsgColors.glass(0.1),
            border: Border.all(
              color: PsgColors.glassBorder(),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            profile.rollNumber,
            style: PsgText.label(
              11,
              letterSpacing: 0.8,
              color: PsgColors.secondary,
              weight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Programme Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                PsgColors.primary.withValues(alpha: 0.15),
                PsgColors.secondary.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: PsgColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            profile.programme,
            style: PsgText.label(
              11,
              letterSpacing: 0.5,
              color: PsgColors.primary,
              weight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<_SectionRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: PsgText.label(
              9,
              letterSpacing: 1.6,
              color: PsgColors.secondary,
              weight: FontWeight.w700,
            ),
          ),
        ),
        Column(
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                borderRadius: 14,
                child: Row(
                  children: [
                    Icon(
                      rows[i].icon,
                      size: 18,
                      color: PsgColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rows[i].label,
                            style: PsgText.label(
                              8,
                              letterSpacing: 0.8,
                              color: PsgColors.onSurfaceVariant,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rows[i].value,
                            style: PsgText.body(
                              13,
                              weight: FontWeight.w500,
                              color: PsgColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (rows[i].copyable)
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: rows[i].value),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${rows[i].label} copied'),
                              duration: const Duration(milliseconds: 800),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: PsgColors.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SectionRow {
  final String label;
  final String value;
  final IconData icon;
  final bool copyable;

  _SectionRow(
    this.label,
    this.value,
    this.icon, {
    this.copyable = false,
  });
}
