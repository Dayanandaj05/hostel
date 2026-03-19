import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../app/app_routes.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../../../student/data/student_profile_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brand constants
// ─────────────────────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0D2137);
const _kTeal = Color(0xFF009688);

// ─────────────────────────────────────────────────────────────────────────────
// Comma-format helper (no intl dependency)
// ─────────────────────────────────────────────────────────────────────────────
String _formatAmount(int amount) {
  final negative = amount < 0;
  final str = (negative ? -amount : amount).toString();
  final buf = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    final pos = str.length - i;
    if (i > 0 && pos % 3 == 0) buf.write(',');
    buf.write(str[i]);
  }
  return '${negative ? '-' : ''}₹ ${buf.toString()}';
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB DEFINITIONS
// ═════════════════════════════════════════════════════════════════════════════
const _tabLabels = [
  'Overview',
  'Room',
  'Mess Details',
  'Leave',
  'Complaints',
  'Notices',
  'Fees',
  'Contact',
];

// Tabs that navigate away instead of showing inline content.
const _navigateTabRoutes = <int, String>{
  3: AppRoutes.studentLeave,
  4: AppRoutes.studentComplaints,
  5: AppRoutes.studentNotices,
};

// ═════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedTab = 0;

  void _selectTab(int index) {
    final route = _navigateTabRoutes[index];
    if (route != null) {
      context.go(route);
      return;
    }
    setState(() => _selectedTab = index);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProviderController.of(context);

    return Scaffold(
      body: Consumer<StudentProfileProvider>(
        builder: (context, profile, _) {
          if (profile.isLoading && profile.profileData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              // ── Header ──
              _buildAppBar(context, authProvider, profile),

              // ── Tab bar ──
              SliverToBoxAdapter(child: _buildTabBar()),

              // ── Tab content ──
              SliverFillRemaining(
                hasScrollBody: true,
                child: _buildTabContent(context, profile),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── SliverAppBar with student info & financial summary ──────────────────

  SliverAppBar _buildAppBar(
    BuildContext context,
    AuthProviderController auth,
    StudentProfileProvider p,
  ) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: _kNavy,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout),
          onPressed: auth.isLoading
              ? null
              : () async {
                  await auth.signOut();
                  if (context.mounted) context.go(AppRoutes.login);
                },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: _kNavy,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 48,
            left: 24,
            right: 24,
            bottom: 16,
          ),
          child: Column(
            children: [
              // Avatar + name row
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: _kTeal,
                    child: Text(
                      p.displayName.isNotEmpty
                          ? p.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.rollNumber,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.bed_outlined,
                                size: 14,
                                  color: Colors.white.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${p.hostelName} · ${p.roomNumber}',
                                style: TextStyle(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Financial summary cards
              Row(
                children: [
                  _FinanceChip(label: 'Establishment', amount: p.establishment),
                  const SizedBox(width: 10),
                  _FinanceChip(label: 'Deposit', amount: p.deposit),
                  const SizedBox(width: 10),
                  _FinanceChip(label: 'Balance', amount: p.balance),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab bar (horizontal scrollable pills) ─────────────────────────────

  Widget _buildTabBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isNav = _navigateTabRoutes.containsKey(i);
          final selected = !isNav && _selectedTab == i;
          return _TabChip(
            label: _tabLabels[i],
            selected: selected,
            isNavigate: isNav,
            onTap: () => _selectTab(i),
          );
        },
      ),
    );
  }

  // ── Tab content switcher ──────────────────────────────────────────────

  Widget _buildTabContent(BuildContext context, StudentProfileProvider p) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: KeyedSubtree(
        key: ValueKey(_selectedTab),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: _tabBodyForIndex(context, _selectedTab, p),
        ),
      ),
    );
  }

  Widget _tabBodyForIndex(
      BuildContext context, int idx, StudentProfileProvider p) {
    return switch (idx) {
      0 => _OverviewTab(profile: p),
      1 => _RoomTab(profile: p),
      2 => _MessTab(profile: p),
      6 => _FeesTab(profile: p),
      7 => _ContactTab(),
      _ => const SizedBox.shrink(), // navigate tabs handled separately
    };
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _FinanceChip extends StatelessWidget {
  const _FinanceChip({required this.label, required this.amount});
  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              _formatAmount(amount),
              style: const TextStyle(
                color: _kNavy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isNavigate = false,
  });
  final String label;
  final bool selected;
  final bool isNavigate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _kNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _kNavy : Colors.grey.shade400,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
            if (isNavigate) ...[
              const SizedBox(width: 4),
              Icon(Icons.open_in_new,
                  size: 12,
                  color: selected ? Colors.white : Colors.grey.shade600),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.trailing});
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Verified',
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _TokenChip extends StatelessWidget {
  const _TokenChip({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? _kTeal.withOpacity(0.15) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: active ? _kTeal : Colors.grey.shade400),
      ),
      child: Text(
        '$label: ${active ? "Yes" : "No"}',
        style: TextStyle(
          color: active ? _kTeal : Colors.grey.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB: OVERVIEW
// ═════════════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.profile});
  final StudentProfileProvider profile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _profileSection()),
              const SizedBox(width: 16),
              Expanded(child: _commSection()),
            ],
          );
        }
        return Column(
          children: [
            _profileSection(),
            _commSection(),
          ],
        );
      },
    );
  }

  Widget _profileSection() {
    return _SectionCard(
      title: 'Profile Details',
      children: [
        _InfoRow(label: 'Full Name', value: profile.displayName),
        _InfoRow(label: 'Roll No', value: profile.rollNumber),
        _InfoRow(label: 'Programme', value: profile.programme),
        _InfoRow(label: 'Class', value: profile.yearOfStudy),
        _InfoRow(label: 'Email', value: profile.email),
        _InfoRow(
          label: 'Contact Phone',
          value: profile.contactPhone,
          trailing: profile.contactPhone != '--' ? const _VerifiedChip() : null,
        ),
        const SizedBox(height: 24),
        const Text(
          'Quick Actions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kNavy),
        ),
        const SizedBox(height: 12),
        _DashboardCardItem(
          title: 'Apply Leave/Gatepass',
          subtitle: 'Request permission to leave the hostel.',
          icon: Icons.exit_to_app_rounded,
          route: AppRoutes.studentLeave,
        ),
        _DashboardCardItem(
          title: 'Book My Token',
          subtitle: 'Pre-book your mess tokens easily.',
          icon: Icons.confirmation_number_rounded,
          route: AppRoutes.studentTokens,
        ),
        _DashboardCardItem(
          title: 'Book T-Shirt',
          subtitle: 'Order PSG hostel t-shirts in your size.',
          icon: Icons.checkroom_rounded,
          route: AppRoutes.studentTShirt,
        ),
      ],
    );
  }

  Widget _commSection() {
    return _SectionCard(
      title: 'Communication Details',
      children: [
        _InfoRow(label: 'Father Name', value: profile.fatherName),
        _InfoRow(label: 'Residential Address', value: profile.address),
        _InfoRow(
          label: 'Primary Mobile',
          value: profile.primaryMobile,
          trailing: profile.primaryMobile != '--' ? const _VerifiedChip() : null,
        ),
        _InfoRow(
          label: 'Secondary Mobile',
          value: profile.secondaryMobile,
          trailing: profile.secondaryMobile != '--' ? const _VerifiedChip() : null,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB: ROOM
// ═════════════════════════════════════════════════════════════════════════════

class _RoomTab extends StatelessWidget {
  const _RoomTab({required this.profile});
  final StudentProfileProvider profile;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Room Details',
      children: [
        _InfoRow(label: 'Hostel Name', value: profile.hostelName),
        _InfoRow(label: 'Block Name', value: profile.blockName),
        _InfoRow(label: 'Room Type', value: profile.roomType),
        _InfoRow(label: 'Joining Date', value: profile.joiningDate),
        _InfoRow(label: 'Floor & Room No', value: '${profile.floor} · ${profile.roomNumber}'),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB: MESS DETAILS
// ═════════════════════════════════════════════════════════════════════════════

class _MessTab extends StatelessWidget {
  const _MessTab({required this.profile});
  final StudentProfileProvider profile;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Mess Details',
      children: [
        _InfoRow(label: 'Mess Name', value: profile.messName),
        _InfoRow(label: 'Mess Type', value: profile.messType),
        _InfoRow(
          label: 'Supervisors',
          value: profile.messSupervisors.isNotEmpty
              ? profile.messSupervisors.join(', ')
              : '--',
        ),
        _InfoRow(label: 'Member Since', value: profile.joiningDate),
        const SizedBox(height: 8),
        Row(
          children: [
            _TokenChip(label: 'Egg Token', active: profile.eggToken),
            const SizedBox(width: 10),
            _TokenChip(label: 'Non Veg Token', active: profile.nonVegToken),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _kTeal,
              side: const BorderSide(color: _kTeal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('View Mess Bill'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mess bill feature coming soon.')),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB: FEES
// ═════════════════════════════════════════════════════════════════════════════

class _FeesTab extends StatelessWidget {
  const _FeesTab({required this.profile});
  final StudentProfileProvider profile;

  @override
  Widget build(BuildContext context) {
    final paid = profile.balance >= 0;
    return _SectionCard(
      title: 'Fee Summary',
      children: [
        _InfoRow(label: 'Establishment', value: _formatAmount(profile.establishment)),
        _InfoRow(label: 'Deposit', value: _formatAmount(profile.deposit)),
        _InfoRow(label: 'Balance', value: _formatAmount(profile.balance)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: paid ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: paid ? Colors.green.shade300 : Colors.red.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                paid ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                color: paid ? Colors.green.shade700 : Colors.red.shade700,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  paid
                      ? 'No outstanding hostel fees. Fees have already been paid.'
                      : 'Outstanding balance: ${_formatAmount(profile.balance)}. Please clear your dues.',
                  style: TextStyle(
                    color: paid ? Colors.green.shade700 : Colors.red.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB: CONTACT
// ═════════════════════════════════════════════════════════════════════════════

class _ContactTab extends StatefulWidget {
  const _ContactTab();

  @override
  State<_ContactTab> createState() => _ContactTabState();
}

class _ContactTabState extends State<_ContactTab> {
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _mobileC = TextEditingController();
  final _messageC = TextEditingController();

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _mobileC.dispose();
    _messageC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(
          title: 'Hostel Office',
          children: [
            _InfoRow(
              label: 'Address',
              value: 'EdviewX, PSG Software Technologies,\nAvinashi Road, Peelamedu,\nCoimbatore 641004',
            ),
            _InfoRow(label: 'Phone', value: '+0422-4344757'),
            _InfoRow(label: 'Email', value: 'hostelsupport.edviewx@psgtech.ac.in'),
            _InfoRow(label: 'Website', value: 'https://edviewx.psgtech.ac.in'),
          ],
        ),
        _SectionCard(
          title: 'Send a Message',
          children: [
            _field(_nameC, 'Name', Icons.person_outline),
            const SizedBox(height: 12),
            _field(_emailC, 'Email', Icons.email_outlined),
            const SizedBox(height: 12),
            _field(_mobileC, 'Mobile', Icons.phone_outlined),
            const SizedBox(height: 12),
            _field(_messageC, 'Message', Icons.message_outlined, maxLines: 4),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _kNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Send Message'),
                onPressed: () {
                  _nameC.clear();
                  _emailC.clear();
                  _mobileC.clear();
                  _messageC.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message sent successfully!'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _DashboardCardItem extends StatelessWidget {
  const _DashboardCardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () => context.go(route),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kNavy.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _kTeal),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: _kNavy),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
