import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hostel_app/app/app_routes.dart';
import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';
import 'package:hostel_app/features/student/data/student_profile_provider.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = AuthProviderController.of(context);
      final uid = auth.user?.uid;
      if (uid != null) {
        context.read<StudentProfileProvider>().startWatching(uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<StudentProfileProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PSG Hostel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Consumer<StudentProfileProvider>(
              builder: (_, p, __) => Text(
                p.displayName,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No new notifications')),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthProviderController.of(context).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProfileStrip(profile),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHomeTab(),
                _buildMessTab(profile),
                _buildFeesTab(profile),
                _buildNoticesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStrip(StudentProfileProvider profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF0D2137),
            child: Text(
              profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : 'S',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  profile.rollNumber,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF009688).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF009688)),
            ),
            child: Text(
              '₹${profile.balance}',
              style: const TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        labelColor: const Color(0xFF0D2137),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF009688),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        tabs: const [
          Tab(icon: Icon(Icons.grid_view_rounded, size: 20), text: 'Home'),
          Tab(icon: Icon(Icons.restaurant_rounded, size: 20), text: 'Mess'),
          Tab(icon: Icon(Icons.receipt_long_rounded, size: 20), text: 'Fees'),
          Tab(icon: Icon(Icons.campaign_rounded, size: 20), text: 'Notices'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final modules = [
      const _ModuleItem('Leave', Icons.flight_takeoff_rounded, AppRoutes.studentLeave),
      const _ModuleItem('Food Token', Icons.fastfood_rounded, AppRoutes.studentTokens),
      const _ModuleItem('T-Shirt', Icons.checkroom_rounded, AppRoutes.studentTShirt),
      const _ModuleItem('Day Entry', Icons.badge_rounded, AppRoutes.studentDayEntry),
      const _ModuleItem('My Room', Icons.meeting_room_rounded, AppRoutes.studentRoom),
      const _ModuleItem('Complaints', Icons.report_problem_rounded, AppRoutes.studentComplaints),
      const _ModuleItem('Notices', Icons.campaign_rounded, AppRoutes.studentNotices),
      const _ModuleItem('Profile', Icons.person_rounded, AppRoutes.studentProfile),
      const _ModuleItem('Contact', Icons.phone_rounded, AppRoutes.studentContact),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final m = modules[index];
        return _buildModuleCard(m);
      },
    );
  }

  Widget _buildModuleCard(_ModuleItem module) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go(module.route),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2137).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(module.icon, color: const Color(0xFF0D2137), size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                module.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessTab(StudentProfileProvider profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2137),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.restaurant_rounded, color: Color(0xFF009688), size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('My Mess', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(
                          profile.messName,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(profile.messType, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Token Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2137)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTokenCard('Egg Token', Icons.egg_rounded, profile.eggToken)),
              const SizedBox(width: 12),
              Expanded(child: _buildTokenCard('Non-Veg Token', Icons.set_meal_rounded, profile.nonVegToken)),
            ],
          ),
          const SizedBox(height: 20),
          if (profile.messSupervisors.isNotEmpty) ...[
            const Text(
              'Supervisors',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2137)),
            ),
            const SizedBox(height: 12),
            ...profile.messSupervisors.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF009688).withValues(alpha: 0.1),
                        child: const Icon(Icons.person, size: 18, color: Color(0xFF009688)),
                      ),
                      const SizedBox(width: 12),
                      Text(s, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('North Indian Mess application coming soon')),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Apply for North Indian Mess'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenCard(String label, IconData icon, bool active) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: active ? const Color(0xFF009688) : Colors.grey.shade300),
      ),
      color: active ? const Color(0xFF009688).withValues(alpha: 0.05) : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: active ? const Color(0xFF009688) : Colors.grey),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              active ? 'Active ✓' : 'Not Active',
              style: TextStyle(fontSize: 11, color: active ? const Color(0xFF009688) : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeesTab(StudentProfileProvider profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fee Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2137)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildFeeCard('Establishment', profile.establishment, const Color(0xFF0D2137))),
              const SizedBox(width: 8),
              Expanded(child: _buildFeeCard('Deposit', profile.deposit, Colors.indigo)),
              const SizedBox(width: 8),
              Expanded(child: _buildFeeCard('Balance', profile.balance, profile.balance > 0 ? Colors.green : Colors.red)),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Payment History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2137)),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'Payment records will appear here.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Redirecting to payment portal...')),
              ),
              icon: const Icon(Icons.payment_rounded),
              label: const Text('Pay Now'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard(String label, int amount, Color color) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '₹$amount',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticesTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notices')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load notices.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('No notices yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index].data() as Map<String, dynamic>;
              final title = doc['title'] ?? 'Untitled Notice';
              final body = doc['body'] ?? '';
              final ts = doc['createdAt'];
              String formattedDate = '';
              if (ts is Timestamp) {
                final dt = ts.toDate();
                formattedDate = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D2137).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.announcement_rounded, color: Color(0xFF0D2137), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          body,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(formattedDate, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ModuleItem {
  final String label;
  final IconData icon;
  final String route;
  const _ModuleItem(this.label, this.icon, this.route);
}
