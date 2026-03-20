import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hostel_app/app/app_routes.dart';
import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';
import 'package:hostel_app/features/auth/domain/entities/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startNavigationTimer();
  }

  void _startNavigationTimer() {
    // 1.2s minimum display time
    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _resolveNavigation();
    });
  }

  void _resolveNavigation() {
    final auth = context.read<AuthProviderController>();
    
    // Wait if still initializing
    if (auth.isLoading) {
      Timer(const Duration(milliseconds: 500), _resolveNavigation);
      return;
    }

    if (!auth.isAuthenticated) {
      context.go(AppRoutes.login);
      return;
    }

    final roleHome = switch (auth.role) {
      UserRole.student => AppRoutes.studentHome,
      UserRole.warden => AppRoutes.wardenHome,
      UserRole.admin => AppRoutes.adminHome,
      _ => AppRoutes.login,
    };

    context.go(roleHome);
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0D2137);

    return Scaffold(
      backgroundColor: navy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // PSG Diamond Logo (Placeholder Icon for now, assuming themed icon)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.diamond_outlined,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PSG Hostel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Resident Portal',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
