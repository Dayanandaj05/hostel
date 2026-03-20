import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/app_routes.dart';

class AdminHostelDayScreen extends StatefulWidget {
  const AdminHostelDayScreen({super.key});

  @override
  State<AdminHostelDayScreen> createState() => _AdminHostelDayScreenState();
}

class _AdminHostelDayScreenState extends State<AdminHostelDayScreen> {
  final _eventNameController = TextEditingController();
  final _venueController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  bool _registrationOpen = false;
  int _maxVisitors = 4;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _venueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('hostel_day')
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _eventNameController.text = data['eventName'] as String? ?? '';
          _venueController.text = data['venue'] as String? ?? '';
          _notesController.text = data['notes'] as String? ?? '';
          _registrationOpen = data['registrationOpen'] as bool? ?? false;
          _maxVisitors = (data['maxVisitorsPerStudent'] as num?)?.toInt() ?? 4;
          final ts = data['eventDate'] as Timestamp?;
          _selectedDate = ts?.toDate();
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the event date')),
      );
      return;
    }
    if (_eventNameController.text.trim().isEmpty || _venueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event name and venue are required')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('hostel_day')
          .set({
        'eventName': _eventNameController.text.trim(),
        'venue': _venueController.text.trim(),
        'notes': _notesController.text.trim(),
        'eventDate': Timestamp.fromDate(_selectedDate!),
        'registrationOpen': _registrationOpen,
        'maxVisitorsPerStudent': _maxVisitors,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hostel Day configuration saved.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        foregroundColor: Colors.white,
        title: const Text('Hostel Day Config'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go(AppRoutes.adminHome),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () => context.go(AppRoutes.adminHome),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D2137), Color(0xFF1E4080)],
                          ),
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
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Annual Hostel Day',
                                    style: TextStyle(color: Colors.white,
                                        fontWeight: FontWeight.bold, fontSize: 18)),
                                  Text('Configure event details and registration',
                                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Registration toggle
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _registrationOpen
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _registrationOpen
                                      ? Icons.lock_open_rounded
                                      : Icons.lock_rounded,
                                  color: _registrationOpen ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Registration Status',
                                      style: TextStyle(fontWeight: FontWeight.bold,
                                          fontSize: 14, color: Color(0xFF0D2137))),
                                    Text(
                                      _registrationOpen
                                          ? 'Open — Students can register'
                                          : 'Closed — No new registrations',
                                      style: TextStyle(
                                        color: _registrationOpen ? Colors.green : Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _registrationOpen,
                                activeTrackColor: Colors.green,
                                onChanged: (v) => setState(() => _registrationOpen = v),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Event name
                      TextField(
                        controller: _eventNameController,
                        decoration: InputDecoration(
                          labelText: 'Event Name',
                          hintText: 'e.g. Hostel Day 2025-26',
                          prefixIcon: const Icon(Icons.event_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Event date picker
                      InkWell(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: _selectedDate != null
                                  ? const Color(0xFF009688)
                                  : Colors.grey.shade400,
                              width: _selectedDate != null ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_rounded,
                                size: 20,
                                color: _selectedDate != null
                                    ? const Color(0xFF009688)
                                    : Colors.grey.shade500),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDate == null
                                      ? 'Select Event Date *'
                                      : '${_selectedDate!.day.toString().padLeft(2, '0')}/'
                                          '${_selectedDate!.month.toString().padLeft(2, '0')}/'
                                          '${_selectedDate!.year}',
                                  style: TextStyle(
                                    color: _selectedDate == null
                                        ? Colors.grey.shade500
                                        : const Color(0xFF0D2137),
                                    fontSize: 15,
                                    fontWeight: _selectedDate != null
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              const Icon(Icons.edit_calendar_rounded,
                                  size: 18, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Venue
                      TextField(
                        controller: _venueController,
                        decoration: InputDecoration(
                          labelText: 'Venue',
                          hintText: 'e.g. PSG Tech Main Ground',
                          prefixIcon: const Icon(Icons.location_on_rounded),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Max visitors stepper
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.group_rounded,
                                  color: Color(0xFF009688), size: 20),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Max Family Members per Student',
                                      style: TextStyle(fontWeight: FontWeight.bold,
                                          fontSize: 13, color: Color(0xFF0D2137))),
                                    Text('How many visitors each student can bring',
                                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _maxVisitors > 1
                                        ? () => setState(() => _maxVisitors--)
                                        : null,
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: const Color(0xFF0D2137),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      '$_maxVisitors',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF0D2137),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _maxVisitors < 10
                                        ? () => setState(() => _maxVisitors++)
                                        : null,
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: const Color(0xFF009688),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Notes
                      TextField(
                        controller: _notesController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Message to Students (optional)',
                          hintText: 'Shown when registration is closed or as event info',
                          alignLabelWithHint: true,
                          prefixIcon: const Icon(Icons.info_outline_rounded),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Live registrations count
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('day_entry_registrations')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.docs.length ?? 0;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF009688).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF009688).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.people_rounded,
                                    color: Color(0xFF009688), size: 22),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$count',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                        color: Color(0xFF0D2137),
                                      ),
                                    ),
                                    const Text('Total Hostel Day Registrations',
                                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.save_rounded),
                          label: Text(_saving ? 'Saving...' : 'Save Configuration'),
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
                ),
              ),
            ),
    );
  }
}
