import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/navbar_items.dart';
import '../widgets/static_nav_bar.dart';
import '../../app/app_routes.dart';
import '../../features/notifications/data/notification_provider.dart';

class StudentShellLayout extends StatefulWidget {
  final Widget child;

  const StudentShellLayout({super.key, required this.child});

  @override
  State<StudentShellLayout> createState() => _StudentShellLayoutState();
}

class _StudentShellLayoutState extends State<StudentShellLayout> {
  late int _currentIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurrentIndex();
  }

  void _updateCurrentIndex() {
    final location = GoRouterState.of(context).uri.path;
    _currentIndex = _getIndexFromRoute(location);
  }

  int _getIndexFromRoute(String location) {
    switch (location) {
      case AppRoutes.studentHome:
        return 0;
      case AppRoutes.studentTokens:
        return 1;
      case AppRoutes.studentFees:
        return 2;
      case AppRoutes.studentNotices:
        return 3;
      case AppRoutes.studentLeave:
        return 4;
      default:
        return 0;
    }
  }

  void _onNavTap(int index) {
    final routes = [
      AppRoutes.studentHome,
      AppRoutes.studentTokens,
      AppRoutes.studentFees,
      AppRoutes.studentNotices,
      AppRoutes.studentLeave,
    ];

    if (index < routes.length) {
      context.go(routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();

    return Stack(
      children: [
        widget.child,
        StaticNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          items: NavbarConfig.studentCompactItems,
          badgeCounts: notificationProvider.badgeCounts,
        ),
      ],
    );
  }
}
