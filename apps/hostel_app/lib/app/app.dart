import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/presentation/controllers/auth_provider_controller.dart';
import '../core/theme/theme.dart';
import 'app_router.dart';

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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
