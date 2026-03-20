import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hostel_app/app/app.dart';
import 'package:hostel_app/core/auth/auth_session_provider.dart';
import 'package:hostel_app/firebase_options.dart';
import 'package:hostel_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';
import 'package:hostel_app/features/complaints/data/repositories/firestore_complaint_repository.dart';
import 'package:hostel_app/features/complaints/domain/repositories/complaint_repository.dart';
import 'package:hostel_app/features/leave/data/repositories/firestore_leave_request_repository.dart';
import 'package:hostel_app/features/leave/domain/repositories/leave_request_repository.dart';
import 'package:hostel_app/features/leave/presentation/controllers/leave_request_controller.dart';
import 'package:hostel_app/features/tokens/data/repositories/firestore_food_token_repository.dart';
import 'package:hostel_app/features/tokens/presentation/controllers/food_token_controller.dart';
import 'package:hostel_app/features/tshirt/data/repositories/firestore_tshirt_repository.dart';
import 'package:hostel_app/features/tshirt/presentation/controllers/tshirt_controller.dart';
import 'package:hostel_app/features/student/data/student_profile_provider.dart';
import 'package:hostel_app/services/storage/firestore_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('Unhandled error: $error');
      debugPrintStack(stackTrace: stack);
    }
    return true;
  };

  final firebaseReady = await _initializeFirebaseSafely();

  if (firebaseReady) {
    await _configureFirebaseMessaging();
  }

  runApp(HostelManagementBootstrap(firebaseReady: firebaseReady));
}

Future<bool> _initializeFirebaseSafely() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (e) {
    debugPrint('Firebase init failed: $e');
    return false;
  }
}

Future<void> _configureFirebaseMessaging() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final firebaseMessaging = FirebaseMessaging.instance;
  await firebaseMessaging.setAutoInitEnabled(true);

  await firebaseMessaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
  );

  FirebaseMessaging.onMessage.listen((message) {
    if (kDebugMode) {
      debugPrint('Foreground FCM: ${message.messageId}');
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    if (kDebugMode) {
      debugPrint('Opened from FCM: ${message.messageId}');
    }
  });
}

class HostelManagementBootstrap extends StatefulWidget {
  const HostelManagementBootstrap({
    required this.firebaseReady,
    super.key,
  });

  final bool firebaseReady;

  @override
  State<HostelManagementBootstrap> createState() => _HostelManagementBootstrapState();
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthSessionProvider>.value(value: _authSessionProvider),
      ],
      builder: (context, _) {
        final firestore = widget.firebaseReady 
            ? FirebaseFirestore.instance 
            : null; // We'll handle nulls in service if needed, or just mock.
            
        final authService = AuthService(
          firebaseAuth: widget.firebaseReady ? FirebaseAuth.instance : null as dynamic,
          firestore: firestore as dynamic,
        );

        final firestoreService = FirestoreService(firestore as dynamic);
        final leaveRepository = FirestoreLeaveRequestRepository(firestoreService);
        final foodTokenRepository = FirestoreFoodTokenRepository(firestoreService);
        final tshirtRepository = FirestoreTShirtRepository(firestoreService);

        return MultiProvider(
          providers: [
            Provider<AuthService>.value(value: authService),
            Provider<FirestoreService>.value(value: firestoreService),
            Provider<LeaveRequestRepository>.value(value: leaveRepository),
            Provider<ComplaintRepository>(
              create: (_) => FirestoreComplaintRepository(firestoreService),
            ),
            ChangeNotifierProvider<StudentProfileProvider>(
              create: (_) => StudentProfileProvider(firestore as dynamic),
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
          ],
          child: const HostelManagementApp(),
        );
      },
    );
  }
}
