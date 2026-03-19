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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDBMwfAghaUT0NS82zUZTFnBw9-jydnj60',
    appId: '1:251911023605:web:ec4ec02252da49802bcebc',
    messagingSenderId: '251911023605',
    projectId: 'psg-hostel-app',
    authDomain: 'psg-hostel-app.firebaseapp.com',
    storageBucket: 'psg-hostel-app.firebasestorage.app',
    measurementId: 'G-RFFM02MXJH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAvglhfOEZ6tGPg6LztCQty7R-KTnHYV9M',
    appId: '1:251911023605:android:62c9213a8ede85ed2bcebc',
    messagingSenderId: '251911023605',
    projectId: 'psg-hostel-app',
    storageBucket: 'psg-hostel-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCOFNjoNkBhb3JZupxmfxpE4cTBeZHG-1Y',
    appId: '1:251911023605:ios:87720860a9e5a4252bcebc',
    messagingSenderId: '251911023605',
    projectId: 'psg-hostel-app',
    storageBucket: 'psg-hostel-app.firebasestorage.app',
    iosBundleId: 'com.example.hostelApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCOFNjoNkBhb3JZupxmfxpE4cTBeZHG-1Y',
    appId: '1:251911023605:ios:87720860a9e5a4252bcebc',
    messagingSenderId: '251911023605',
    projectId: 'psg-hostel-app',
    storageBucket: 'psg-hostel-app.firebasestorage.app',
    iosBundleId: 'com.example.hostelApp',
  );
}