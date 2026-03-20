import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../../../student/data/student_profile_provider.dart';
import '../../../domain/entities/day_entry_model.dart';
import '../../controllers/day_entry_controller.dart';

class DayEntryScreen extends StatefulWidget {
  const DayEntryScreen({super.key});

  @override
  State<DayEntryScreen> createState() => _DayEntryScreenState();
}

class _DayEntryScreenState extends State<DayEntryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  final List<DayEntryVisitor> _visitors = [];

  final List<String> _timeSlots = [
    'Morning (9AM-12PM)',
    'Afternoon (12PM-3PM)',
    'Evening (3PM-6PM)',
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Visitor',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D2137),
                    ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
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
                        mobileController.text.length == 10) {
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

  void _submitRegistration() async {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select visit date and time slot')),
      );
      return;
    }

    final userId = AuthProviderController.of(context).user?.uid;
    final profile = context.read<StudentProfileProvider>();

    if (userId == null) return;

    final success = await context.read<DayEntryController>().registerDayEntry(
          userId: userId,
          studentName: profile.displayName,
          rollNumber: profile.rollNumber,
          roomNumber: profile.roomNumber,
          programme: profile.programme,
          visitDate: _selectedDate!,
          timeSlot: _selectedTimeSlot!,
          visitors: _visitors,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<DayEntryController>().successMessage!)),
      );
      setState(() {
        _selectedDate = null;
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
        title: const Text('Day Entry Pass'),
        backgroundColor: const Color(0xFF0D2137),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF009688),
          tabs: const [
            Tab(text: 'Register'),
            Tab(text: 'My Passes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRegisterTab(),
          _buildMyPassesTab(),
        ],
      ),
    );
  }

  Widget _buildRegisterTab() {
    final profile = context.watch<StudentProfileProvider>();
    final controller = context.watch<DayEntryController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade800),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Day Entry registration is open for the Annual Open Day. Register yourself and your visitors below.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Visit Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2137)),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20, color: Color(0xFF009688)),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null
                        ? 'Select Visit Date'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: TextStyle(
                      color: _selectedDate == null ? Colors.grey.shade600 : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedTimeSlot,
            decoration: const InputDecoration(
              labelText: 'Select Time Slot',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.access_time, color: Color(0xFF009688)),
            ),
            items: _timeSlots
                .map((slot) => DropdownMenuItem(value: slot, child: Text(slot)))
                .toList(),
            onChanged: (val) => setState(() => _selectedTimeSlot = val),
          ),
          const SizedBox(height: 24),
          const Text(
            'Student Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2137)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                _buildInfoRow('Name', profile.displayName),
                const Divider(),
                _buildInfoRow('Roll Number', profile.rollNumber),
                const Divider(),
                _buildInfoRow('Room', profile.roomNumber),
                const Divider(),
                _buildInfoRow('Programme', profile.programme),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add Visitors (Optional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2137)),
              ),
              Text(
                '${_visitors.length}/4',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._visitors.map((v) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF009688),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${v.relation} • ${v.mobile}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => setState(() => _visitors.remove(v)),
                  ),
                ),
              )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _visitors.length >= 4 ? null : _addVisitor,
              icon: const Icon(Icons.add),
              label: const Text('Add Visitor'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF009688),
                side: const BorderSide(color: Color(0xFF009688)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.isSubmitting ? null : _submitRegistration,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D2137),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: controller.isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Register for Day Entry', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMyPassesTab() {
    final controller = context.watch<DayEntryController>();

    if (controller.isLoadingRegistrations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.myRegistrations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No registrations yet',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 18),
            ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side (Navy)
          Container(
            width: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF0D2137),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    entry.passNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Dashed line divider (simplified with a vertical line)
          Container(
            width: 1,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(vertical: 16),
          ),
          // Right side (White)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DATE',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                          ),
                          Text(
                            '${entry.visitDate.day}/${entry.visitDate.month}/${entry.visitDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'TIME SLOT',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                          ),
                          Text(
                            entry.timeSlot.split(' ')[0],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'STUDENT',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  ),
                  Text(
                    entry.studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    entry.rollNumber,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 16, color: Color(0xFF009688)),
                      const SizedBox(width: 8),
                      Text(
                        entry.visitors.isEmpty
                            ? 'No visitors'
                            : '${entry.visitors.length} visitors',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
