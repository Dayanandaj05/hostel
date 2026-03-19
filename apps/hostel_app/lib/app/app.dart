import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/controllers/auth_provider_controller.dart';
import '../core/theme/theme.dart';
import 'app_router.dart';

class HostelManagementApp extends StatelessWidget {
  const HostelManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProviderController?>(
      builder: (context, authProvider, _) {
        if (authProvider == null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Hostel Management System',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Hostel Management System',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          routerConfig: AppRouter.build(authProvider),
        );
      },
    );
  }
}
