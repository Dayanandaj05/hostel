import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../config/navbar_items.dart';
import '../widgets/static_nav_bar.dart';

class WardenShellLayout extends StatefulWidget {
  final Widget child;

  const WardenShellLayout({super.key, required this.child});

  @override
  State<WardenShellLayout> createState() => _WardenShellLayoutState();
}

class _WardenShellLayoutState extends State<WardenShellLayout> {
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
      case AppRoutes.wardenHome:
        return 0;
      case AppRoutes.wardenLeaveRequests:
        return 1;
      case AppRoutes.wardenMessApplications:
        return 2;
      case AppRoutes.wardenComplaints:
        return 3;
      case AppRoutes.wardenNotices:
        return 4;
      default:
        return 0;
    }
  }

  void _onNavTap(int index) {
    final routes = [
      AppRoutes.wardenHome,
      AppRoutes.wardenLeaveRequests,
      AppRoutes.wardenMessApplications,
      AppRoutes.wardenComplaints,
      AppRoutes.wardenNotices,
    ];
    if (index < routes.length) {
      context.go(routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        StaticNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          items: NavbarConfig.wardenCompactItems,
        ),
      ],
    );
  }
}
