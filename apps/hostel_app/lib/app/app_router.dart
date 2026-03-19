import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
import '../features/dashboard/presentation/pages/student/student_dashboard_screen.dart';
import '../features/tokens/presentation/pages/student/book_token_screen.dart';
import '../features/leave/domain/repositories/leave_request_repository.dart';
import '../features/leave/presentation/controllers/leave_request_controller.dart';
import '../features/leave/presentation/pages/student/leave_request_screen.dart';

final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const unauthorized = '/unauthorized';

  static const studentHome = '/student';
  static const studentRoom = '/student/room';
  static const studentLeave = '/student/leave';
  static const studentComplaints = '/student/complaints';
  static const studentTokens = '/student/tokens';
  static const studentNotices = '/student/notices';
  static const studentProfile = '/student/profile';
  static const studentMess = '/student/mess';
  static const studentFees = '/student/fees';
  static const studentContact = '/student/contact';

  static const wardenHome = '/warden';
  static const wardenLeaveRequests = '/warden/leave-requests';
  static const wardenComplaints = '/warden/complaints';
  static const wardenNotices = '/warden/notices';

  static const adminHome = '/admin';
  static const adminUsers = '/admin/users';
  static const adminRoles = '/admin/roles';
  static const adminRooms = '/admin/rooms';
  static const adminNotices = '/admin/notices';
  static const adminDashboard = '/admin/dashboard';
}

final class AppRouter {
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

        final role = authProvider.role;
        if (role == null) {
          return AppRoutes.unauthorized;
        }

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
          builder: (_, __) => const _PlaceholderPage(
            title: 'Room Information',
            description: 'View and manage your room allocation.',
          ),
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
          builder: (_, __) => const _PlaceholderPage(
            title: 'Notices',
            description: 'View hostel notices and announcements.',
          ),
        ),
        GoRoute(
          path: AppRoutes.studentTokens,
          builder: (context, state) => const BookTokenScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentProfile,
          builder: (_, __) => const _PlaceholderPage(
            title: 'Profile',
            description: 'View your student profile details.',
          ),
        ),
        GoRoute(
          path: AppRoutes.studentMess,
          builder: (_, __) => const _PlaceholderPage(
            title: 'Mess Details',
            description: 'View mess information and billing.',
          ),
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
          builder: (_, __) => const _PlaceholderPage(
            title: 'Contact',
            description: 'Contact the hostel office.',
          ),
        ),
        GoRoute(
          path: AppRoutes.wardenHome,
          builder: (_, __) => const _PlaceholderPage(
            title: 'Warden Dashboard',
            description: 'Manage your hostel and students.',
          ),
        ),
        GoRoute(
          path: AppRoutes.wardenLeaveRequests,
          builder: (_, __) => const _PlaceholderPage(
            title: 'Leave Requests',
            description: 'Approve or reject student leave requests.',
          ),
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
          builder: (_, __) => const _PlaceholderPage(
            title: 'Post Notices',
            description: 'Broadcast announcements to students.',
          ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (authProvider.isAuthenticated)
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: authProvider.isLoading
                  ? null
                  : () async {
                      await authProvider.signOut();
                      if (context.mounted) {
                        context.go(AppRoutes.login);
                      }
                    },
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              const Text(
                '(Placeholder - Feature under development)',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
