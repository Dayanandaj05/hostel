import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/presentation/controllers/auth_provider_controller.dart';
import '../core/design/psg_design_system.dart';
import 'app_router.dart';

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

class HostelManagementApp extends StatefulWidget {
  const HostelManagementApp({super.key});

  @override
  State<HostelManagementApp> createState() => _HostelManagementAppState();
}

class _HostelManagementAppState extends State<HostelManagementApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Initialize the router once. It will stay stable and react to
    // authProvider changes via refreshListenable.
    _router = AppRouter.build(context.read<AuthProviderController>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Hostel Management System',
      theme: PsgTheme.light,
      scrollBehavior: const _AppScrollBehavior(),
      routerConfig: _router,
    );
  }
}
