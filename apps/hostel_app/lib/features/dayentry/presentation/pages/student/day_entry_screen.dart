import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../../../student/data/student_profile_provider.dart';
import '../../../domain/entities/day_entry_model.dart';
import '../../controllers/day_entry_controller.dart';
import '../../../../../app/app_routes.dart';

class DayEntryScreen extends StatefulWidget {
  const DayEntryScreen({super.key});

  @override
  State<DayEntryScreen> createState() => _DayEntryScreenState();
}

class _DayEntryScreenState extends State<DayEntryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _selectedTimeSlot;
  final List<DayEntryVisitor> _visitors = [];

  final List<String> _timeSlots = [
    'Morning Session (9AM-12PM)',
    'Afternoon Session (12PM-3PM)',
    'Full Day (9AM-5PM)',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = AuthProviderController.of(context).user?.uid;
      if (userId != null) {
        context.read<DayEntryController>().startWatchingRegistrations(userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addVisitor() {
    if (_visitors.length >= 4) return;

    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    String? selectedRelation;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Family Member',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: const Color(0xFF0D2137))),
              const SizedBox(height: 6),
              Text('Add a parent or guardian attending Hostel Day with you',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Relation',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.family_restroom),
                ),
                items: ['Father', 'Mother', 'Guardian', 'Sibling', 'Other']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => selectedRelation = val,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_android),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2137),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        selectedRelation != null &&
                        mobileController.text.length >= 10) {
                      setState(() {
                        _visitors.add(DayEntryVisitor(
                          name: nameController.text,
                          relation: selectedRelation!,
                          mobile: mobileController.text,
                        ));
                      });
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields correctly')),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitRegistrationWithDate(
      DateTime eventDate, StudentProfileProvider profile) async {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a session')),
      );
      return;
    }

    final userId = AuthProviderController.of(context).user?.uid;
    if (userId == null) return;

    final success = await context.read<DayEntryController>().registerDayEntry(
          userId: userId,
          studentName: profile.displayName,
          rollNumber: profile.rollNumber,
          roomNumber: profile.roomNumber,
          programme: profile.programme,
          visitDate: eventDate,
          timeSlot: _selectedTimeSlot!,
          visitors: _visitors,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            context.read<DayEntryController>().successMessage!)),
      );
      setState(() {
        _selectedTimeSlot = null;
        _visitors.clear();
      });
      _tabController.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostel Day'),
        backgroundColor: const Color(0xFF0D2137),
        foregroundColor: Colors.white,
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF009688),
          tabs: const [
            Tab(text: 'Register'),
            Tab(text: 'My Registration'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRegisterTab(),
          _buildMyRegistrationTab(),
        ],
      ),
    );
  }

  Widget _buildRegisterTab() {
    final profile = context.watch<StudentProfileProvider>();
    final controller = context.watch<DayEntryController>();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('settings')
          .doc('hostel_day')
          .snapshots(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Not configured yet
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Hostel Day Not Announced',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF0D2137), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('The event date has not been set yet. Check back later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final registrationOpen = data['registrationOpen'] as bool? ?? false;
        final eventName = data['eventName'] as String? ?? 'Annual Hostel Day';
        final venue = data['venue'] as String? ?? '--';
        final notes = data['notes'] as String? ?? '';
        final maxVisitors = (data['maxVisitorsPerStudent'] as num?)?.toInt() ?? 4;
        final eventTs = data['eventDate'] as Timestamp?;
        final eventDate = eventTs?.toDate();
        final dateStr = eventDate == null ? '--'
            : '${eventDate.day.toString().padLeft(2, '0')}/'
              '${eventDate.month.toString().padLeft(2, '0')}/'
              '${eventDate.year}';

        // Registration closed
        if (!registrationOpen) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Event banner still shown
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D2137), Color(0xFF1E4080)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.celebration_rounded,
                            color: Color(0xFF009688), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(eventName,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(dateStr,
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_rounded, color: Colors.orange, size: 36),
                      const SizedBox(height: 12),
                      const Text('Registration Closed',
                        style: TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 16, color: Color(0xFF0D2137))),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(notes,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Registration open — show form
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D2137), Color(0xFF1E4080)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D2137).withValues(alpha: 0.3),
                      blurRadius: 12, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.celebration_rounded,
                              color: Color(0xFF009688), size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(eventName,
                                style: const TextStyle(color: Colors.white,
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('PSG Institutions',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _eventInfoChip(Icons.calendar_today_rounded, dateStr),
                        const SizedBox(width: 10),
                        Expanded(child: _eventInfoChip(Icons.location_on_rounded, venue)),
                      ],
                    ),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(notes,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12, height: 1.4)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Session selection
              const Text('Select Your Session',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: Color(0xFF0D2137))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _selectedTimeSlot,
                decoration: InputDecoration(
                  labelText: 'Session',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.access_time_rounded,
                      color: Color(0xFF009688)),
                ),
                items: _timeSlots
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedTimeSlot = val),
              ),
              const SizedBox(height: 24),

              // Your details
              const Text('Your Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: Color(0xFF0D2137))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _infoRow('Name', profile.displayName, Icons.person_rounded),
                    const Divider(height: 20),
                    _infoRow('Roll Number', profile.rollNumber, Icons.badge_rounded),
                    const Divider(height: 20),
                    _infoRow('Room', profile.roomNumber, Icons.meeting_room_rounded),
                    const Divider(height: 20),
                    _infoRow('Programme', profile.programme, Icons.school_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Family members
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Family Members',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                        color: Color(0xFF0D2137))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D2137).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${_visitors.length}/$maxVisitors',
                      style: const TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 13, color: Color(0xFF0D2137))),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Invite up to $maxVisitors family members to attend with you',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 12),

              ..._visitors.map((v) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF009688).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          const Color(0xFF009688).withValues(alpha: 0.1),
                      child: const Icon(Icons.person, size: 18,
                          color: Color(0xFF009688)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.name, style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${v.relation} • ${v.mobile}',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red, size: 20),
                      onPressed: () => setState(() => _visitors.remove(v)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              )),

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _visitors.length >= maxVisitors ? null : _addVisitor,
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Add Family Member'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF009688),
                    side: const BorderSide(color: Color(0xFF009688)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: controller.isSubmitting
                      ? null
                      : () => _submitRegistrationWithDate(eventDate!, profile),
                  icon: controller.isSubmitting
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.celebration_rounded),
                  label: Text(controller.isSubmitting
                      ? 'Registering...' : 'Register for Hostel Day'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2137),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _eventInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF009688)),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Widget _buildMyRegistrationTab() {
    final controller = context.watch<DayEntryController>();

    if (controller.isLoadingRegistrations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.myRegistrations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No Hostel Day registration yet',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Register for the annual Hostel Day event',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.myRegistrations.length,
      itemBuilder: (context, index) {
        final entry = controller.myRegistrations[index];
        return _buildPassCard(entry);
      },
    );
  }

  Widget _buildPassCard(DayEntryModel entry) {
    final statusColor = switch (entry.status.toLowerCase()) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.orange,
    };

    final dateStr = '${entry.visitDate.day.toString().padLeft(2,'0')}/'
        '${entry.visitDate.month.toString().padLeft(2,'0')}/'
        '${entry.visitDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D2137), Color(0xFF1E4080)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.celebration_rounded, color: Color(0xFF009688), size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Annual Hostel Day Pass',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    entry.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _passRow(Icons.confirmation_number_rounded, 'Pass Number', entry.passNumber),
                const Divider(height: 16),
                _passRow(Icons.person_rounded, 'Student', entry.studentName),
                const Divider(height: 16),
                _passRow(Icons.badge_rounded, 'Roll Number', entry.rollNumber),
                const Divider(height: 16),
                _passRow(Icons.event_rounded, 'Event Date', dateStr),
                const Divider(height: 16),
                _passRow(Icons.access_time_rounded, 'Session', entry.timeSlot),
                if (entry.visitors.isNotEmpty) ...[
                  const Divider(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.group_rounded, size: 18, color: Color(0xFF009688)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Family Members (${entry.visitors.length})',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(height: 4),
                          ...entry.visitors.map((v) => Text(
                            '• ${v.name} (${v.relation})',
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                          )),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _passRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF009688)),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
