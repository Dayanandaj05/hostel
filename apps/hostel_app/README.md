# hostel_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase deployment quick start

### 1) Mobile build readiness (Android/iOS)

1. Ensure native Firebase config files are present through CI secret injection.
2. Build mobile artifacts:
   flutter pub get
   flutter analyze (must pass clean)
   flutter build apk --release
   flutter build ios --release
   flutter build ios --release

### 2) Web build readiness

Web initialization uses compile-time dart-define values. Supply:
- FIREBASE_WEB_API_KEY
- FIREBASE_WEB_APP_ID
- FIREBASE_WEB_MESSAGING_SENDER_ID
- FIREBASE_WEB_PROJECT_ID
- FIREBASE_WEB_AUTH_DOMAIN (optional)
- FIREBASE_WEB_STORAGE_BUCKET (optional)

Example:

flutter build web --release \
  --dart-define=FIREBASE_WEB_API_KEY=... \
  --dart-define=FIREBASE_WEB_APP_ID=... \
  --dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_WEB_PROJECT_ID=... \
  --dart-define=FIREBASE_WEB_AUTH_DOMAIN=... \
  --dart-define=FIREBASE_WEB_STORAGE_BUCKET=...

### 3) Firebase console + admin panel operations

1. Create users in Firebase Authentication.
2. Assign role claims with scripts/set-custom-claims.mjs.
3. Verify role-aware access through firestore.rules.
4. Manage domain operations from the in-app admin screens (users, roles, notices, rooms, statistics).

## Security hardening

### 1) Rotate exposed Firebase API keys

1. In Google Cloud Console, go to APIs & Services > Credentials.
2. Create new Android/iOS/Web keys and update Firebase app config with the new keys.
3. Delete old keys after rollout is verified.

### 2) Restrict keys by app and API

For Android keys:
- Set Application restrictions to Android apps.
- Add package name + SHA-1 signing certificate fingerprint.

For iOS keys:
- Set Application restrictions to iOS apps.
- Add iOS bundle ID.

For web keys:
- Set Application restrictions to HTTP referrers.

For all keys:
- Set API restrictions to only Firebase/Google APIs actually used by the app.

### 3) Keep Firebase config files out of git

The following files are gitignored and must be injected from secrets:
- android/app/google-services.json
- ios/Runner/GoogleService-Info.plist
- macos/Runner/GoogleService-Info.plist
- lib/firebase_options.dart

GitHub Actions secret names used by CI:
- FIREBASE_OPTIONS_DART (full content of lib/firebase_options.dart)
- ANDROID_GOOGLE_SERVICES_JSON_B64 (base64)
- IOS_GOOGLE_SERVICE_INFO_PLIST_B64 (base64)
- MACOS_GOOGLE_SERVICE_INFO_PLIST_B64 (base64)

Local/dev generation example:

FIREBASE_OPTIONS_DART="$(cat /secure/path/firebase_options.dart)" ./scripts/write-firebase-options.sh

### 4) Role checks with custom claims (recommended)

Prefer Firebase Auth custom claims for role authorization in Firestore rules.
This repo includes an admin helper:

scripts/set-custom-claims.mjs

Example:

node scripts/set-custom-claims.mjs --uid "<firebase-uid>" --role "admin"

### 5) Do not trust role/flags from clients

- Never allow normal clients to assign/upgrade role.
- Validate incoming fields in Firestore rules.
- Use privileged admin/Cloud Functions flows for sensitive flags and approvals.
