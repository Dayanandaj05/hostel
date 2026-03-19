import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'app/app.dart';
import 'core/auth/auth_session_provider.dart';
import 'firebase_options.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/controllers/auth_provider_controller.dart';
import 'features/complaints/data/repositories/firestore_complaint_repository.dart';
import 'features/complaints/domain/repositories/complaint_repository.dart';
import 'features/leave/data/repositories/firestore_leave_request_repository.dart';
import 'features/leave/domain/repositories/leave_request_repository.dart';
import 'services/storage/firestore_service.dart';

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
  return false;
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

class HostelManagementBootstrap extends StatelessWidget {
  const HostelManagementBootstrap({
    required this.firebaseReady,
    super.key,
  });

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    final providers = <SingleChildWidget>[
      ChangeNotifierProvider<AuthSessionProvider>(
        create: (_) => AuthSessionProvider()..initialize(),
      ),
    ];

    if (firebaseReady) {
      final firebaseAuth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      final authService = AuthService(
        firebaseAuth: firebaseAuth,
        firestore: firestore,
      );

      final firestoreService = FirestoreService(firestore);
      final leaveRepository = FirestoreLeaveRequestRepository(firestoreService);
      final complaintRepository = FirestoreComplaintRepository(firestoreService);

      providers.addAll([
        Provider<AuthService>.value(value: authService),
        Provider<FirestoreService>.value(value: firestoreService),
        Provider<LeaveRequestRepository>.value(value: leaveRepository),
        Provider<ComplaintRepository>.value(value: complaintRepository),
        ChangeNotifierProvider<AuthProviderController>(
          create: (_) => AuthProviderController(authService)..initialize(),
        ),
      ]);
    }

    return MultiProvider(
      providers: providers,
      child: const HostelManagementApp(),
    );
  }
}
