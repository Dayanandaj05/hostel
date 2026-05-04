import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hostel_app/app/app_routes.dart';
import '../../../../../core/design/psg_design_system.dart';
import '../../../../../core/widgets/static_nav_bar.dart';

class StudentContactScreen extends StatelessWidget {
  const StudentContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = [
      const _Contact('Hostel Office', '0422-4344000', Icons.home_work_rounded,
          isPhone: true),
      const _Contact('Chief Warden', '0422-4344001', Icons.person_rounded,
          isPhone: true),
      const _Contact('Security', '0422-4344002', Icons.security_rounded,
          isPhone: true),
      const _Contact(
          'Mess Supervisor', '0422-4344003', Icons.restaurant_rounded,
          isPhone: true),
      const _Contact(
          'Medical Room', '0422-4344004', Icons.local_hospital_rounded,
          isPhone: true),
      const _Contact('Email', 'hostel@psgtech.ac.in', Icons.email_rounded,
          isPhone: false),
      const _Contact(
        'Address',
        'PSG College of Technology, Avinashi Road, Peelamedu, Coimbatore - 641 004',
        Icons.location_on_rounded,
        isPhone: false,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: PsgGlassAppBar(
        title: 'Contact Us',
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
      body: MeshBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 88,
            16,
            StaticNavBar.reservedBottomPadding(context) + 16,
          ),
          children: [
            _buildHeader(),
            ...contacts.map((contact) => _buildContactCard(context, contact)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: const Row(
          children: [
            Icon(Icons.support_agent_rounded,
                color: PsgColors.primary, size: 36),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PSG Hostel Support',
                    style: TextStyle(
                      color: PsgColors.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'We\'re here to help you 24/7',
                    style: TextStyle(
                      color: PsgColors.onSurfaceVariant,
                      fontSize: 13,
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

  Widget _buildContactCard(BuildContext context, _Contact contact) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: PsgColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(contact.icon, color: PsgColors.primary, size: 22),
          ),
          title: Text(
            contact.name,
            style: PsgText.label(14, color: PsgColors.onSurface),
          ),
          subtitle: Text(
            contact.detail,
            style: PsgText.body(13, color: PsgColors.onSurfaceVariant),
          ),
          trailing: contact.isPhone
              ? IconButton(
                  icon: const Icon(Icons.call_rounded, color: PsgColors.green),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling ${contact.detail}...')),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _Contact {
  final String name;
  final String detail;
  final IconData icon;
  final bool isPhone;
  const _Contact(this.name, this.detail, this.icon, {required this.isPhone});
}
