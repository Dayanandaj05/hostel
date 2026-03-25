import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hostel_app/app/app.dart';
import 'package:hostel_app/core/auth/auth_session_provider.dart';
import 'package:hostel_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';
import 'package:hostel_app/features/complaints/data/repositories/mock_complaint_repository.dart';
import 'package:hostel_app/features/complaints/domain/repositories/complaint_repository.dart';
import 'package:hostel_app/features/dayentry/data/repositories/mock_day_entry_repository.dart';
import 'package:hostel_app/features/dayentry/presentation/controllers/day_entry_controller.dart';
import 'package:hostel_app/features/leave/data/repositories/mock_leave_request_repository.dart';
import 'package:hostel_app/features/leave/domain/repositories/leave_request_repository.dart';
import 'package:hostel_app/features/leave/presentation/controllers/leave_request_controller.dart';
import 'package:hostel_app/features/student/data/student_profile_provider.dart';
import 'package:hostel_app/features/tokens/data/repositories/mock_food_token_repository.dart';
import 'package:hostel_app/features/tokens/domain/repositories/food_token_repository.dart';
import 'package:hostel_app/features/tokens/presentation/controllers/food_token_controller.dart';
import 'package:hostel_app/features/tshirt/data/repositories/mock_tshirt_repository.dart';
import 'package:hostel_app/features/tshirt/presentation/controllers/tshirt_controller.dart';
import 'package:hostel_app/features/notifications/data/notification_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  runApp(const HostelManagementBootstrap());
}

Future<void> _initializeFirebase() async {
  try {
    if (kIsWeb) {
      const apiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
      const appId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
      const messagingSenderId = String.fromEnvironment(
        'FIREBASE_WEB_MESSAGING_SENDER_ID',
      );
      const projectId = String.fromEnvironment('FIREBASE_WEB_PROJECT_ID');
      const authDomain = String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN');
      const storageBucket = String.fromEnvironment(
        'FIREBASE_WEB_STORAGE_BUCKET',
      );

      if (apiKey.isNotEmpty &&
          appId.isNotEmpty &&
          messagingSenderId.isNotEmpty &&
          projectId.isNotEmpty) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: apiKey,
            appId: appId,
            messagingSenderId: messagingSenderId,
            projectId: projectId,
            authDomain: authDomain.isNotEmpty ? authDomain : null,
            storageBucket: storageBucket.isNotEmpty ? storageBucket : null,
          ),
        );
        return;
      }

      debugPrint(
        'Firebase web options are not configured. Supply dart-define values for web deployment.',
      );
      return;
    }

    await Firebase.initializeApp();
  } catch (error) {
    debugPrint('Firebase initialization skipped: $error');
  }
}

class HostelManagementBootstrap extends StatefulWidget {
  const HostelManagementBootstrap({super.key});

  @override
  State<HostelManagementBootstrap> createState() =>
      _HostelManagementBootstrapState();
}

class _HostelManagementBootstrapState extends State<HostelManagementBootstrap> {
  late final AuthSessionProvider _authSessionProvider;

  @override
  void initState() {
    super.initState();
    _authSessionProvider = AuthSessionProvider()..initialize();
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final leaveRepository = MockLeaveRequestRepository();
    final foodTokenRepository = MockFoodTokenRepository();
    final tshirtRepository = MockTShirtRepository();
    final dayEntryRepository = MockDayEntryRepository();
    final complaintRepository = MockComplaintRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthSessionProvider>.value(
          value: _authSessionProvider,
        ),
        Provider<AuthService>.value(value: authService),
        Provider<LeaveRequestRepository>.value(value: leaveRepository),
        Provider<FoodTokenRepository>.value(value: foodTokenRepository),
        Provider<ComplaintRepository>.value(value: complaintRepository),
        ChangeNotifierProvider<StudentProfileProvider>(
          create: (_) => StudentProfileProvider(),
        ),
        ChangeNotifierProvider<LeaveRequestController>(
          create: (_) => LeaveRequestController(leaveRepository),
        ),
        ChangeNotifierProvider<AuthProviderController>(
          create: (_) => AuthProviderController(authService)..initialize(),
        ),
        ChangeNotifierProvider<FoodTokenController>(
          create: (_) => FoodTokenController(foodTokenRepository),
        ),
        ChangeNotifierProvider<TShirtController>(
          create: (_) => TShirtController(tshirtRepository),
        ),
        ChangeNotifierProvider<DayEntryController>(
          create: (_) => DayEntryController(dayEntryRepository),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: const HostelManagementApp(),
    );
  }
}
