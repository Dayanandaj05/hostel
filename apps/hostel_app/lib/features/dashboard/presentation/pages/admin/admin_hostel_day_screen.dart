import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hostel_app/core/design/psg_design_system.dart';

class AdminHostelDayScreen extends StatefulWidget {
  const AdminHostelDayScreen({super.key});

  @override
  State<AdminHostelDayScreen> createState() => _AdminHostelDayScreenState();
}

class _AdminHostelDayScreenState extends State<AdminHostelDayScreen> {
  final _nameController = TextEditingController();
  final _venueController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime? _selectedDate;
  bool _registrationOpen = false;
  int _maxVisitors = 2;
  
  bool _isLoadingConfig = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('hostel_day').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _nameController.text = data['eventName'] ?? '';
        _venueController.text = data['venue'] ?? '';
        _notesController.text = data['notes'] ?? '';
        
        if (data['eventDate'] is Timestamp) {
          _selectedDate = (data['eventDate'] as Timestamp).toDate();
        }
        
        _registrationOpen = data['registrationOpen'] ?? false;
        _maxVisitors = data['maxVisitorsPerStudent'] ?? 2;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading config: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingConfig = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: PsgColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _saveConfig() async {
    if (_nameController.text.trim().isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Date are required')));
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      await FirebaseFirestore.instance.collection('settings').doc('hostel_day').set({
        'eventName': _nameController.text.trim(),
        'eventDate': Timestamp.fromDate(_selectedDate!),
        'venue': _venueController.text.trim(),
        'registrationOpen': _registrationOpen,
        'maxVisitorsPerStudent': _maxVisitors,
        'notes': _notesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save settings: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PsgText.label(14, color: PsgColors.onSurfaceVariant)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: PsgText.body(14, color: PsgColors.onSurface),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: PsgColors.primary), borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: PsgColors.primary, size: 20),
            onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
          ),
          title: 'Hostel Day Settings',
        ),
        body: SafeArea(
          bottom: false,
          child: _isLoadingConfig
              ? const Center(child: CircularProgressIndicator(color: PsgColors.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                  child: Column(
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Live Status', style: PsgText.headline(18, color: PsgColors.primary)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _registrationOpen ? PsgColors.green.withValues(alpha: 0.15) : PsgColors.error.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _registrationOpen ? PsgColors.green.withValues(alpha: 0.3) : PsgColors.error.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    _registrationOpen ? 'REGISTRATIONS OPEN' : 'REGISTRATIONS CLOSED',
                                    style: PsgText.label(10, letterSpacing: 0.8, color: _registrationOpen ? PsgColors.green : PsgColors.error),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance.collection('day_entry_registrations').snapshots(),
                              builder: (context, snapshot) {
                                final count = snapshot.data?.docs.length ?? 0;
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(count.toString(), style: PsgText.headline(40, color: PsgColors.onSurface)),
                                      Text('Total Student Registrations', style: PsgText.body(14, color: PsgColors.onSurfaceVariant)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Event Details', style: PsgText.headline(18, color: PsgColors.primary)),
                            const SizedBox(height: 20),
                            _buildTextField('Event Name', _nameController),
                            const SizedBox(height: 16),
                            Text('Event Date', style: PsgText.label(14, color: PsgColors.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedDate != null ? DateFormat('dd MMM yyyy').format(_selectedDate!) : 'Select Date',
                                      style: PsgText.body(14, color: _selectedDate != null ? PsgColors.onSurface : PsgColors.onSurfaceVariant),
                                    ),
                                    const Icon(Icons.calendar_today_rounded, size: 18, color: PsgColors.primary),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField('Venue', _venueController),
                            const SizedBox(height: 20),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Registrations Open', style: PsgText.body(14, color: PsgColors.onSurface)),
                                Switch(
                                  value: _registrationOpen,
                                  activeTrackColor: PsgColors.primary.withValues(alpha: 0.5),
                                  activeThumbColor: PsgColors.primary,
                                  onChanged: (val) => setState(() => _registrationOpen = val),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Max Visitors / Student', style: PsgText.body(14, color: PsgColors.onSurface)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: PsgColors.primary),
                                      onPressed: _maxVisitors > 1 ? () => setState(() => _maxVisitors--) : null,
                                    ),
                                    Text('$_maxVisitors', style: PsgText.headline(16, color: PsgColors.onSurface)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: PsgColors.primary),
                                      onPressed: _maxVisitors < 10 ? () => setState(() => _maxVisitors++) : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 20),
                            _buildTextField('Instructions for Students', _notesController, maxLines: 4),
                            const SizedBox(height: 24),
                            PsgFilledButton(
                              label: 'Save Configuration',
                              loading: _isSaving,
                              onPressed: _saveConfig,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
