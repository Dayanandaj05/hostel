import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hostel_app/app/app_routes.dart';
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
    return Consumer<StudentProfileProvider>(
      builder: (context, profile, _) {
        if (profile.isLoading && profile.profileData == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (profile.error != null) {
          return Center(child: Text(profile.error!));
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D2137),
            foregroundColor: Colors.white,
            title: const Text('My Profile'),
            elevation: 0,
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
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showEditProfileSheet(context, profile),
            backgroundColor: const Color(0xFF009688),
            child: const Icon(Icons.edit, color: Colors.white),
          ),
          body: SingleChildScrollView(
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
                        _InfoRow('Blood Group', profile.bloodGroup, Icons.bloodtype_rounded, copyable: false),
                      ]),
                      _buildSection('Address', [
                        _InfoRow('Address', profile.address, Icons.location_on_rounded, copyable: false),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileSheet(BuildContext context, StudentProfileProvider profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditProfileBottomSheet(profile: profile),
    );
  }

  Widget _buildHeader(StudentProfileProvider profile) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF1E4080)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF009688), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF009688).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: const Color(0xFF009688),
                  child: Text(
                    profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              profile.rollNumber,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF009688),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              profile.programme,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
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

class _EditProfileBottomSheet extends StatefulWidget {
  final StudentProfileProvider profile;
  const _EditProfileBottomSheet({required this.profile});

  @override
  State<_EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<_EditProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _primaryMobileController;
  late TextEditingController _secondaryMobileController;
  late TextEditingController _addressController;
  String? _bloodGroup;
  bool _isLoading = false;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _primaryMobileController = TextEditingController(text: widget.profile.primaryMobile == '--' ? '' : widget.profile.primaryMobile);
    _secondaryMobileController = TextEditingController(text: widget.profile.secondaryMobile == '--' ? '' : widget.profile.secondaryMobile);
    _addressController = TextEditingController(text: widget.profile.address == '--' ? '' : widget.profile.address);
    _bloodGroup = _bloodGroups.contains(widget.profile.bloodGroup) ? widget.profile.bloodGroup : null;
  }

  @override
  void dispose() {
    _primaryMobileController.dispose();
    _secondaryMobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      await widget.profile.updateProfile(
        primaryMobile: _primaryMobileController.text.trim(),
        secondaryMobile: _secondaryMobileController.text.trim(),
        address: _addressController.text.trim(),
        bloodGroup: _bloodGroup,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                   IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _primaryMobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Primary Mobile',
                  prefixIcon: Icon(Icons.phone_android_rounded),
                ),
                validator: (val) => (val?.length ?? 0) < 10 ? 'Enter valid mobile number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _secondaryMobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Secondary Mobile',
                  prefixIcon: Icon(Icons.phone_android_rounded),
                ),
                validator: (val) => (val != null && val.isNotEmpty && val.length < 10) ? 'Enter valid mobile number' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _bloodGroup,
                items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
                onChanged: (val) => setState(() => _bloodGroup = val),
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  prefixIcon: Icon(Icons.bloodtype_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('SAVE UPDATES'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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

