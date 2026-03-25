import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hostel_app/app/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:hostel_app/core/design/psg_design_system.dart';

import 'package:hostel_app/features/student/data/student_profile_provider.dart';

class StudentFeesScreen extends StatelessWidget {
  const StudentFeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<StudentProfileProvider>();
    final establishment = 50000;
    final deposit = 5000;
    final paid = 53800;
    final balance = establishment + deposit - paid;

    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          scrollOffset: 0,
          title: 'Fees & Payments',
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: PsgColors.primary,
              size: 20,
            ),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.studentHome),
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 88,
            bottom: 40,
            left: 20,
            right: 20,
          ),
          children: [
            Text(
              'Payment Summary',
              style: PsgText.headline(26, color: PsgColors.primary),
            ),
            const SizedBox(height: 12),
            GlassCard(
              borderRadius: 16,
              child: ListTile(
                title: const Text('Student'),
                subtitle: Text(profile.displayName),
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              borderRadius: 16,
              child: Column(
                children: [
                  _row('Establishment', establishment),
                  _row('Deposit', deposit),
                  _row('Paid', paid),
                  _row('Balance', balance),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Payment History',
              style: PsgText.headline(18, color: PsgColors.primary),
            ),
            const SizedBox(height: 8),
            const GlassCard(
              borderRadius: 14,
              child: ListTile(
                title: Text('Initial Payment'),
                trailing: Text('₹53,800'),
              ),
            ),
            const SizedBox(height: 10),
            const GlassCard(
              borderRadius: 14,
              child: ListTile(
                title: Text('No data available'),
                subtitle: Text('More payments will appear here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, int amount) {
    return ListTile(
      title: Text(label),
      trailing: Text('₹$amount'),
      dense: true,
    );
  }
}
