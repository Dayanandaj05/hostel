import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'This starter is configured for Android, macOS + Web only. '
          'Run "flutterfire configure" to add more platforms.',
        );
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'DUMMY_WEB_API_KEY',
    appId: 'DUMMY_WEB_APP_ID',
    messagingSenderId: 'DUMMY_WEB_SENDER_ID',
    projectId: 'DUMMY_PROJECT_ID',
    authDomain: 'DUMMY_WEB_AUTH_DOMAIN',
    storageBucket: 'DUMMY_STORAGE_BUCKET',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'DUMMY_ANDROID_API_KEY',
    appId: 'DUMMY_ANDROID_APP_ID',
    messagingSenderId: 'DUMMY_ANDROID_SENDER_ID',
    projectId: 'DUMMY_PROJECT_ID',
    storageBucket: 'DUMMY_STORAGE_BUCKET',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'DUMMY_MACOS_API_KEY',
    appId: 'DUMMY_MACOS_APP_ID',
    messagingSenderId: 'DUMMY_MACOS_SENDER_ID',
    projectId: 'DUMMY_PROJECT_ID',
    storageBucket: 'DUMMY_STORAGE_BUCKET',
    iosBundleId: 'DUMMY_MACOS_BUNDLE_ID',
  );
}
