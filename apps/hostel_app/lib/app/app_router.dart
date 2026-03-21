import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_routes.dart';
import '../features/auth/domain/entities/user_model.dart';
import '../features/auth/presentation/controllers/auth_provider_controller.dart';
import '../features/auth/presentation/pages/common/login_screen.dart';
import '../features/auth/presentation/pages/common/splash_screen.dart';
import '../features/complaints/domain/repositories/complaint_repository.dart';
import '../features/complaints/presentation/controllers/complaint_controller.dart';
import '../features/complaints/presentation/pages/student/complaint_submission_screen.dart';
import '../features/complaints/presentation/pages/warden/warden_complaints_screen.dart';
import '../features/dashboard/presentation/pages/admin/admin_dashboard_screen.dart';
import '../features/dashboard/presentation/pages/admin/admin_mess_menu_screen.dart';
import '../features/dashboard/presentation/pages/admin/admin_notice_post_screen.dart';
import '../features/dashboard/presentation/pages/admin/admin_role_assignment_screen.dart';
import '../features/dashboard/presentation/pages/admin/admin_room_allocation_screen.dart';
import '../features/dashboard/presentation/pages/admin/admin_statistics_screen.dart';
import '../features/dashboard/presentation/pages/admin/admin_user_management_screen.dart';
import '../features/dashboard/presentation/pages/admin/admin_hostel_day_screen.dart';
import '../features/dashboard/presentation/pages/student/student_dashboard_screen.dart';
import '../features/mess/presentation/pages/student/book_token_screen.dart';
import '../features/leave/presentation/pages/student/leave_request_screen.dart';
import '../features/tshirt/presentation/pages/student/tshirt_screen.dart';
import '../features/dayentry/presentation/pages/student/day_entry_screen.dart';
import '../features/dashboard/presentation/pages/student/student_profile_screen.dart';
import '../features/dashboard/presentation/pages/student/student_contact_screen.dart';
import '../features/dashboard/presentation/pages/student/student_room_screen.dart';
import '../features/dashboard/presentation/pages/student/student_notices_screen.dart';
import '../features/dashboard/presentation/pages/student/mess_application_screen.dart';
import '../features/dashboard/presentation/pages/warden/warden_dashboard_screen.dart';
import '../features/dashboard/presentation/pages/warden/warden_mess_applications_screen.dart';
import '../features/dashboard/presentation/pages/warden/warden_leave_requests_screen.dart';
import '../features/dashboard/presentation/pages/warden/warden_notice_screen.dart';
import '../features/tokens/presentation/pages/student/my_tokens_screen.dart';
import '../features/dashboard/presentation/pages/student/student_fees_screen.dart';
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
          return isLoginRoute ? null : AppRoutes.login;
        }

        final role = authProvider.role!;
        final roleHome = switch (role) {
          UserRole.student => AppRoutes.studentHome,
          UserRole.warden => AppRoutes.wardenHome,
          UserRole.admin => AppRoutes.adminHome,
        };

        if (location == AppRoutes.splash || location == AppRoutes.login) {
          return roleHome;
        }

        if (location == AppRoutes.unauthorized) return null;

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
          pageBuilder: (context, state) => _buildPage(const SplashScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.login,
          pageBuilder: (context, state) => _buildPage(const LoginScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.unauthorized,
          pageBuilder: (context, state) => _buildPage(const _UnauthorizedPage(), state),
        ),
        
        // --- Student Routes ---
        GoRoute(
          path: AppRoutes.studentHome,
          pageBuilder: (context, state) => _buildPage(const StudentDashboardScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.studentRoom,
          pageBuilder: (context, state) => _buildPage(const StudentRoomScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.studentLeave,
          pageBuilder: (context, state) => _buildPage(const LeaveRequestScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.studentComplaints,
          pageBuilder: (context, state) => _buildPage(
            ChangeNotifierProvider<ComplaintController>(
              create: (_) => ComplaintController(context.read<ComplaintRepository>()),
              child: const ComplaintSubmissionScreen(),
            ), state),
        ),
        GoRoute(
          path: AppRoutes.studentNotices,
          pageBuilder: (context, state) => _buildPage(const StudentNoticesScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.studentTokens,
          pageBuilder: (context, state) => _buildPage(const BookTokenScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.studentTShirt,
          pageBuilder: (context, state) => _buildPage(const TShirtScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.studentMyTokens,
          pageBuilder: (context, state) => _buildPage(const MyTokensScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.studentMyTShirts,
          pageBuilder: (context, state) => _buildPage(const TShirtListScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.studentDayEntry,
          pageBuilder: (context, state) => _buildPage(const DayEntryScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.studentProfile,
          pageBuilder: (context, state) => _buildPage(const StudentProfileScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.studentMess,
          pageBuilder: (context, state) => _buildPage(const _PlaceholderPage(
            title: 'Mess Details',
            description: 'View mess information and billing.',
          ), state),
        ),
        GoRoute(
          path: '/student/mess-application',
          pageBuilder: (context, state) => _buildPage(const MessApplicationScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.studentFees,
          pageBuilder: (context, state) => _buildPage(const StudentFeesScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.studentContact,
          pageBuilder: (context, state) => _buildPage(const StudentContactScreen(), state),
        ),

        // --- Warden Routes ---
        GoRoute(
          path: AppRoutes.wardenHome,
          pageBuilder: (context, state) => _buildPage(const WardenDashboardScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.wardenLeaveRequests,
          pageBuilder: (context, state) => _buildPage(const WardenLeaveRequestsScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.wardenMessApplications,
          pageBuilder: (context, state) => _buildPage(const WardenMessApplicationsScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.wardenComplaints,
          pageBuilder: (context, state) => _buildPage(
            ChangeNotifierProvider<ComplaintController>(
              create: (_) => ComplaintController(context.read<ComplaintRepository>()),
              child: const WardenComplaintsScreen(),
            ), state),
        ),
        GoRoute(
          path: AppRoutes.wardenNotices,
          pageBuilder: (context, state) => _buildPage(const WardenNoticeScreen(), state),
        ),

        // --- Admin Routes ---
        GoRoute(
          path: AppRoutes.adminHome,
          pageBuilder: (context, state) => _buildPage(const AdminDashboardScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.adminUsers,
          pageBuilder: (context, state) => _buildPage(const AdminUserManagementScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.adminRoles,
          pageBuilder: (context, state) => _buildPage(const AdminRoleAssignmentScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.adminRooms,
          pageBuilder: (context, state) => _buildPage(const AdminRoomAllocationScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.adminMessMenu,
          pageBuilder: (context, state) => _buildPage(const AdminMessMenuScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.adminNotices,
          pageBuilder: (context, state) => _buildPage(const AdminNoticePostScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.adminDashboard,
          pageBuilder: (context, state) => _buildPage(const AdminStatisticsScreen(), state),
        ),
        GoRoute(
          path: AppRoutes.adminHostelDay,
          pageBuilder: (context, state) => _buildPage(const AdminHostelDayScreen(), state),
        ),
      ],
    );
  }

  static CustomTransitionPage _buildPage(Widget child, GoRouterState state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.01, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
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
