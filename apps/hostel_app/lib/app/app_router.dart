import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_routes.dart';
import '../features/auth/domain/entities/user_model.dart';
import '../features/auth/presentation/controllers/auth_provider_controller.dart';
import '../features/auth/presentation/pages/common/login_screen.dart';
import '../features/complaints/domain/repositories/complaint_repository.dart';
import '../features/complaints/presentation/controllers/complaint_controller.dart';
import '../features/complaints/presentation/pages/student/complaint_submission_screen.dart';
import '../features/complaints/presentation/pages/warden/warden_complaints_screen.dart';
import '../features/dashboard/presentation/pages/admin/admin_dashboard_screen.dart';
import '../features/dashboard/presentation/pages/admin/admin_notice_post_screen.dart';
import '../features/dashboard/presentation/pages/admin/admin_role_assignment_screen.dart';
import '../features/dashboard/presentation/pages/admin/admin_room_allocation_screen.dart';
import '../features/dashboard/presentation/pages/admin/admin_statistics_screen.dart';
import '../features/dashboard/presentation/pages/admin/admin_user_management_screen.dart';
import '../features/dashboard/presentation/pages/admin/admin_hostel_day_screen.dart';
import '../features/dashboard/presentation/pages/student/student_dashboard_screen.dart';
import '../features/tokens/presentation/pages/student/book_token_screen.dart';
import '../features/leave/presentation/pages/student/leave_request_screen.dart';
import '../features/tshirt/presentation/pages/student/tshirt_screen.dart';
import '../features/dayentry/presentation/pages/student/day_entry_screen.dart';
import '../features/dashboard/presentation/pages/student/student_profile_screen.dart';
import '../features/dashboard/presentation/pages/student/student_contact_screen.dart';
import '../features/dashboard/presentation/pages/student/student_room_screen.dart';
import '../features/dashboard/presentation/pages/student/student_notices_screen.dart';
import '../features/dashboard/presentation/pages/student/mess_application_screen.dart';
import '../features/dashboard/presentation/pages/warden/warden_dashboard_screen.dart';
import '../features/dashboard/presentation/pages/warden/warden_leave_requests_screen.dart';
import '../features/dashboard/presentation/pages/warden/warden_notice_screen.dart';
import '../features/tokens/presentation/pages/student/my_tokens_screen.dart';
import '../features/tshirt/presentation/pages/student/tshirt_list_screen.dart';

abstract class AppRouter {
  static GoRouter build(AuthProviderController authProvider) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final location = state.uri.path;
        final isLoginRoute = location == AppRoutes.login;

        if (!authProvider.isAuthenticated) {
          // Unauthenticated users can only be on the login page.
          return isLoginRoute ? null : AppRoutes.login;
        }

        // isAuthenticated guarantees _user != null and role is set.
        final role = authProvider.role!;

        final roleHome = switch (role) {
          UserRole.student => AppRoutes.studentHome,
          UserRole.warden => AppRoutes.wardenHome,
          UserRole.admin => AppRoutes.adminHome,
        };

        if (location == AppRoutes.splash || location == AppRoutes.login) {
          return roleHome;
        }

        if (location == AppRoutes.unauthorized) {
          return null;
        }

        final allowedPrefix = switch (role) {
          UserRole.student => '/student',
          UserRole.warden => '/warden',
          UserRole.admin => '/admin',
        };

        if (!location.startsWith(allowedPrefix)) {
          return AppRoutes.unauthorized;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (_, __) => const _SplashPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.unauthorized,
          builder: (_, __) => const _UnauthorizedPage(),
        ),
        GoRoute(
          path: AppRoutes.studentHome,
          builder: (_, __) => const StudentDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentRoom,
          builder: (_, __) => const StudentRoomScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentLeave,
          builder: (context, _) => const LeaveRequestScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentComplaints,
          builder: (context, _) => ChangeNotifierProvider<ComplaintController>(
            create: (_) => ComplaintController(
              context.read<ComplaintRepository>(),
            ),
            child: const ComplaintSubmissionScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.studentNotices,
          builder: (_, __) => const StudentNoticesScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentTokens,
          builder: (context, state) => const BookTokenScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentTShirt,
          builder: (context, state) => const TShirtScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentMyTokens,
          builder: (_, __) => const MyTokensScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentMyTShirts,
          builder: (_, __) => const TShirtListScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentDayEntry,
          builder: (_, __) => const DayEntryScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentProfile,
          builder: (_, __) => const StudentProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentMess,
          builder: (_, __) => const _PlaceholderPage(
            title: 'Mess Details',
            description: 'View mess information and billing.',
          ),
        ),
        GoRoute(
          path: '/student/mess-application',
          builder: (context, state) => const MessApplicationScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentFees,
          builder: (_, __) => const _PlaceholderPage(
            title: 'Fees',
            description: 'View hostel fee details and payment status.',
          ),
        ),
        GoRoute(
          path: AppRoutes.studentContact,
          builder: (_, __) => const StudentContactScreen(),
        ),
        GoRoute(
          path: AppRoutes.wardenHome,
          builder: (_, __) => const WardenDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.wardenLeaveRequests,
          builder: (_, __) => const WardenLeaveRequestsScreen(),
        ),
        GoRoute(
          path: AppRoutes.wardenComplaints,
          builder: (context, _) => ChangeNotifierProvider<ComplaintController>(
            create: (_) => ComplaintController(
              context.read<ComplaintRepository>(),
            ),
            child: const WardenComplaintsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.wardenNotices,
          builder: (_, __) => const WardenNoticeScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminHome,
          builder: (_, __) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminUsers,
          builder: (_, __) => const AdminUserManagementScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminRoles,
          builder: (_, __) => const AdminRoleAssignmentScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminRooms,
          builder: (_, __) => const AdminRoomAllocationScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminNotices,
          builder: (_, __) => const AdminNoticePostScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminDashboard,
          builder: (_, __) => const AdminStatisticsScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminHostelDay,
          builder: (_, __) => const AdminHostelDayScreen(),
        ),
      ],
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 64),
            const SizedBox(height: 16),
            Text(
              'Hostel Management',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _UnauthorizedPage extends StatelessWidget {
  const _UnauthorizedPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unauthorized')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Access Denied',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'You do not have permission to view this page.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.splash),
              child: const Text('Return Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProviderController.of(context);

    final homeRoute = switch (authProvider.role) {
      UserRole.warden => AppRoutes.wardenHome,
      UserRole.admin => AppRoutes.adminHome,
      _ => AppRoutes.studentHome,
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        foregroundColor: Colors.white,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go(homeRoute),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () => context.go(homeRoute),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction_rounded, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Feature under development',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
