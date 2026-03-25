import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../config/navbar_items.dart';
import '../widgets/static_nav_bar.dart';

class AdminShellLayout extends StatefulWidget {
  final Widget child;

  const AdminShellLayout({super.key, required this.child});

  @override
  State<AdminShellLayout> createState() => _AdminShellLayoutState();
}

class _AdminShellLayoutState extends State<AdminShellLayout> {
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
      case AppRoutes.adminHome:
        return 0;
      case AppRoutes.adminUsers:
        return 1;
      case AppRoutes.adminRoles:
        return 2;
      case AppRoutes.adminRooms:
        return 3;
      case AppRoutes.adminNotices:
        return 4;
      default:
        return 0;
    }
  }

  void _onNavTap(int index) {
    final routes = [
      AppRoutes.adminHome,
      AppRoutes.adminUsers,
      AppRoutes.adminRoles,
      AppRoutes.adminRooms,
      AppRoutes.adminNotices,
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
          items: NavbarConfig.adminCompactItems,
        ),
      ],
    );
  }
}
