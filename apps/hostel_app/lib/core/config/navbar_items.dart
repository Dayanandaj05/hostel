import 'package:flutter/material.dart';
import '../../app/app_routes.dart';

// Extended navigation item with route information
class NavItem {
  final String label;
  final IconData icon;
  final String route;
  final String? badgeKey; // Key to look up badge count in NotificationProvider

  NavItem({
    required this.label,
    required this.icon,
    required this.route,
    this.badgeKey,
  });
}

abstract class NavbarConfig {
  // Student navigation items
  static final studentNavItems = [
    NavItem(
      label: 'Home',
      icon: Icons.home_rounded,
      route: AppRoutes.studentHome,
    ),
    NavItem(
      label: 'Tokens',
      icon: Icons.card_giftcard_rounded,
      route: AppRoutes.studentTokens,
    ),
    NavItem(
      label: 'Fees',
      icon: Icons.currency_rupee_rounded,
      route: AppRoutes.studentFees,
    ),
    NavItem(
      label: 'Notices',
      icon: Icons.notifications_active_rounded,
      route: AppRoutes.studentNotices,
    ),
    NavItem(
      label: 'Leave',
      icon: Icons.calendar_month_rounded,
      route: AppRoutes.studentLeave,
    ),
  ];

  // Compact pill items for students (quick access subset)
  static final studentCompactItems = [
    studentNavItems[0], // Home
    studentNavItems[1], // Tokens
    studentNavItems[2], // Fees
    NavItem(
      label: 'Notices',
      icon: Icons.notifications_active_rounded,
      route: AppRoutes.studentNotices,
      badgeKey: 'notices',
    ),
    NavItem(
      label: 'Leave',
      icon: Icons.calendar_month_rounded,
      route: AppRoutes.studentLeave,
      badgeKey: 'leave',
    ),
  ];

  // Warden navigation items
  static final wardenNavItems = [
    NavItem(
      label: 'Home',
      icon: Icons.home_rounded,
      route: AppRoutes.wardenHome,
    ),
    NavItem(
      label: 'Leave Requests',
      icon: Icons.event_available_rounded,
      route: AppRoutes.wardenLeaveRequests,
    ),
    NavItem(
      label: 'Mess Applications',
      icon: Icons.restaurant_menu_rounded,
      route: AppRoutes.wardenMessApplications,
    ),
    NavItem(
      label: 'Complaints',
      icon: Icons.report_problem_rounded,
      route: AppRoutes.wardenComplaints,
    ),
    NavItem(
      label: 'Notices',
      icon: Icons.notifications_active_rounded,
      route: AppRoutes.wardenNotices,
    ),
  ];

  // Compact pill items for wardens
  static final wardenCompactItems = [
    NavItem(
      label: 'Home',
      icon: Icons.home_rounded,
      route: AppRoutes.wardenHome,
    ),
    NavItem(
      label: 'Leaves',
      icon: Icons.event_available_rounded,
      route: AppRoutes.wardenLeaveRequests,
    ),
    NavItem(
      label: 'Mess',
      icon: Icons.restaurant_menu_rounded,
      route: AppRoutes.wardenMessApplications,
    ),
    NavItem(
      label: 'Issues',
      icon: Icons.report_problem_rounded,
      route: AppRoutes.wardenComplaints,
    ),
    NavItem(
      label: 'Notices',
      icon: Icons.notifications_active_rounded,
      route: AppRoutes.wardenNotices,
    ),
  ];

  // Admin navigation items
  static final adminNavItems = [
    NavItem(
      label: 'Home',
      icon: Icons.home_rounded,
      route: AppRoutes.adminHome,
    ),
    NavItem(
      label: 'Users',
      icon: Icons.people_rounded,
      route: AppRoutes.adminUsers,
    ),
    NavItem(
      label: 'Rooms',
      icon: Icons.bed_rounded,
      route: AppRoutes.adminRooms,
    ),
    NavItem(
      label: 'Mess Menu',
      icon: Icons.restaurant_menu_rounded,
      route: AppRoutes.adminMessMenu,
    ),
    NavItem(
      label: 'Notices',
      icon: Icons.notifications_active_rounded,
      route: AppRoutes.adminNotices,
    ),
  ];

  // Compact pill items for admins
  static final adminCompactItems = [
    NavItem(
      label: 'Home',
      icon: Icons.home_rounded,
      route: AppRoutes.adminHome,
    ),
    NavItem(
      label: 'Users',
      icon: Icons.people_rounded,
      route: AppRoutes.adminUsers,
    ),
    NavItem(
      label: 'Roles',
      icon: Icons.admin_panel_settings_rounded,
      route: AppRoutes.adminRoles,
    ),
    NavItem(
      label: 'Rooms',
      icon: Icons.bed_rounded,
      route: AppRoutes.adminRooms,
    ),
    NavItem(
      label: 'Notices',
      icon: Icons.notifications_active_rounded,
      route: AppRoutes.adminNotices,
    ),
  ];

  static List<NavItem> getNavItems(String userRole) {
    return switch (userRole.toLowerCase()) {
      'student' => studentNavItems,
      'warden' => wardenNavItems,
      'admin' => adminNavItems,
      _ => [studentNavItems[0]],
    };
  }

  static List<NavItem> getCompactItems(String userRole) {
    return switch (userRole.toLowerCase()) {
      'student' => studentCompactItems,
      'warden' => wardenCompactItems,
      'admin' => adminCompactItems,
      _ => [studentCompactItems[0]],
    };
  }
}
