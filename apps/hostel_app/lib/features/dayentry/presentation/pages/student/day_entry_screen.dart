import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hostel_app/app/app_routes.dart';
import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';
import 'package:hostel_app/features/dayentry/domain/entities/day_entry_model.dart';
import 'package:hostel_app/features/dayentry/presentation/controllers/day_entry_controller.dart';
import 'package:hostel_app/features/student/data/student_profile_provider.dart';

class DayEntryScreen extends StatefulWidget {
  const DayEntryScreen({super.key});

  @override
  State<DayEntryScreen> createState() => _DayEntryScreenState();
}

class _DayEntryScreenState extends State<DayEntryScreen> {
  String _timeSlot = 'Morning Session (9AM-12PM)';
  final _visitors = <DayEntryVisitor>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = AuthProviderController.of(context).user?.uid;
      if (uid != null) {
        context.read<DayEntryController>().startWatchingRegistrations(uid);
      }
    });
  }

  Future<void> _submit() async {
    final uid = AuthProviderController.of(context).user?.uid;
    final profile = context.read<StudentProfileProvider>();
    if (uid == null) return;
    final ok = await context.read<DayEntryController>().registerDayEntry(
          userId: uid,
          studentName: profile.displayName,
          rollNumber: profile.rollNumber,
          roomNumber: profile.roomNumber,
          programme: profile.programme,
          visitDate: DateTime.now().add(const Duration(days: 10)),
          timeSlot: _timeSlot,
          visitors: _visitors.isEmpty
              ? [
                  DayEntryVisitor(
                      name: 'Parent', relation: 'Father', mobile: '9999999999')
                ]
              : _visitors,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              ok ? 'Registration submitted' : 'Failed to submit registration')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DayEntryController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostel Day'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.studentHome),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _timeSlot,
            items: const [
              'Morning Session (9AM-12PM)',
              'Afternoon Session (12PM-3PM)',
              'Full Day (9AM-5PM)',
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _timeSlot = value);
            },
            decoration: const InputDecoration(labelText: 'Session'),
          ),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: controller.isSubmitting ? null : _submit,
              child: const Text('Submit Registration')),
          const SizedBox(height: 20),
          const Text('My Registration',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (controller.isLoadingRegistrations)
            const Center(child: CircularProgressIndicator())
          else if (controller.myRegistrations.isEmpty)
            const Text('No data available')
          else
            ...controller.myRegistrations.map((r) => ListTile(
                  title: Text(r.passNumber),
                  subtitle: Text('${r.timeSlot} • ${r.status}'),
                )),
        ],
      ),
    );
  }
}
