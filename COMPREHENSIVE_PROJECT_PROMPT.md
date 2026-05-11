# PSG Hostel Management System — Comprehensive Project Prompt

**Author:** Dayananda  
**Last Updated:** May 4, 2026  
**Status:** Production-ready Flutter + Firebase application  

---

## 🎯 PROJECT OVERVIEW

**PSG Hostel Management System** is a feature-complete mobile and web application for managing hostel operations at PSG Institute of Technology. It provides role-based dashboards and workflows for **Students**, **Wardens**, and **Admin** staff.

### Key Objectives
- Streamline hostel administration (room allocation, meal management, notifications)
- Enable students to request leave, book food tokens, submit complaints, view fees
- Empower wardens to approve/reject applications and manage day-to-day operations
- Provide admin dashboards for user management, role assignment, statistics

---

## 📱 TECH STACK

| Component | Technology | Version |
|-----------|-----------|---------|
| Frontend | Flutter | Latest (Dart ≥3.5.0) |
| Backend | Firebase (Firestore, Auth, Messaging, Cloud Functions) | Latest |
| State Management | Provider + custom ChangeNotifier controllers | 6.1.2 |
| Navigation | GoRouter | 14.8.1 |
| UI Design System | Glassmorphism theme (custom) | Custom |
| Typography | Google Fonts (Manrope, Inter) | 6.2.1 |
| Charts | fl_chart | 0.68.0 |
| Local Notifications | flutter_local_notifications | 17.1.2 |

---

## 📂 PROJECT STRUCTURE

```
Happ/
├── apps/hostel_app/             # Main Flutter application
│   ├── lib/
│   │   ├── main.dart            # Bootstrap & Firebase init
│   │   ├── app/
│   │   │   ├── app.dart         # MaterialApp.router setup (uses PsgTheme)
│   │   │   ├── app_router.dart  # GoRouter routes & auth guards
│   │   │   └── app_routes.dart  # Route constants
│   │   ├── core/
│   │   │   ├── design/
│   │   │   │   └── psg_design_system.dart  # CENTRALIZED: Colors, Typography, ThemeData
│   │   │   ├── widgets/         # Shared UI components (MeshBackground, GlassCard, PsgGlassAppBar)
│   │   │   ├── layouts/         # Shell layouts per role (StudentShellLayout, WardenShellLayout, AdminShellLayout)
│   │   │   ├── auth/            # Auth session & identity contracts
│   │   │   ├── theme/           # Material Design tokens
│   │   │   └── constants/       # App-wide constants
│   │   ├── services/
│   │   │   ├── storage/firestore_service.dart
│   │   │   ├── auth/auth_service.dart
│   │   │   └── notifications/  # Push notification integrations
│   │   ├── shared/              # Reusable UI widgets (NavBar, Buttons, Cards)
│   │   └── features/            # Feature modules (clean architecture)
│   │       ├── auth/
│   │       ├── dashboard/
│   │       ├── leave/
│   │       ├── tokens/          # Food token booking & inventory
│   │       ├── tshirt/
│   │       ├── dayentry/        # Day entry tracking
│   │       ├── complaints/
│   │       ├── notices/
│   │       ├── rooms/
│   │       ├── student/         # StudentProfileProvider (real-time Firestore sync)
│   │       ├── users/
│   │       └── notifications/   # Push notification provider
│   ├── android/                 # Android native code & build config
│   ├── ios/                     # iOS native code & build config
│   ├── web/                     # Web build artifacts
│   ├── pubspec.yaml             # Dependencies
│   └── README.md
├── firebase/
│   ├── functions/               # Cloud Functions (Node.js)
│   └── firestore.rules          # Security rules (critical for auth/authorization)
├── docs/
│   └── folder_responsibilities.md
├── scripts/
│   ├── set-custom-claims.mjs    # Firebase admin script
│   └── update_admin.js
├── code to replace/             # UI files pending integration (design system implementation)
│   ├── psg_design_system.dart
│   ├── student_dashboard_screen.dart
│   ├── warden_dashboard_screen.dart
│   ├── admin_dashboard_screen.dart
│   ├── leave_request_screen.dart
│   ├── book_token_screen.dart
│   └── IMPLEMENTATION_GUIDE.md
└── .git/                        # Version control
```

---

## 🏗️ ARCHITECTURE PATTERN

### **Feature-First Clean Architecture**

Each feature module (`features/<feature_name>/`) follows a 3-layer structure:

```
features/
├── <feature_name>/
    ├── domain/
    │   ├── entities/             # Pure business models (e.g., LeaveRequest, FoodToken)
    │   ├── repositories/         # Abstract repository contracts
    │   └── usecases/             # Business logic (if complex)
    ├── data/
    │   ├── datasources/          # Firestore queries & external APIs
    │   ├── models/               # DTOs (Firestore serialization)
    │   └── repositories/         # Concrete implementations
    └── presentation/
        ├── controllers/          # ChangeNotifier providers (state management)
        ├── pages/
        │   ├── student/
        │   ├── warden/
        │   └── admin/
        └── widgets/              # Feature-specific UI components
```

### **Role Separation at Routing & Feature Level**

- **Students** access `/student/*` routes → StudentShellLayout → student-specific pages
- **Wardens** access `/warden/*` routes → WardenShellLayout → warden-specific pages  
- **Admin** access `/admin/*` routes → AdminShellLayout → admin-specific pages

This enforces authorization boundaries **both at routing** (via GoRouter guards) **and feature level** (pages live in role-specific subfolders).

---

## 🎨 DESIGN SYSTEM (Critical for All UI Work)

### **Centralized Design System: `lib/core/design/psg_design_system.dart`**

All new UI screens **must** use components from this design system:

```dart
// Colors
PsgColors.primary            // #003F87 (PSG blue)
PsgColors.primaryContainer   // #0056B3
PsgColors.secondary          // #366288
PsgColors.error              // #BA1A1A
PsgColors.background         // #F7F9FB
PsgColors.green              // #15803D
PsgColors.amber              // #B45309
PsgColors.glass(opacity)     // Glassmorphism overlay (white with opacity)
PsgColors.glassBorder()      // White 20% opacity for borders
PsgColors.glassShadow()      // Primary 6% opacity for subtle shadows

// Typography (uses Google Fonts)
PsgText.headline(size, weight: FontWeight.w900, color: null)
  // Manrope, -0.5 letter spacing, for headings
PsgText.body(size, weight: FontWeight.w400, color: null)
  // Inter, regular body text
PsgText.label(size, weight: FontWeight.w700, letterSpacing: 0.8, color: null)
  // Inter, uppercase labels with tracking

// Theme
PsgTheme.light
  // Returns complete ThemeData with Material3, custom app bar, input decoration
  // Use in app/app.dart: theme: PsgTheme.light
```

### **Glassmorphism Pattern**

The design system implements **glassmorphism** with:
- `BackdropFilter` with blur values (tune in `psg_design_system.dart` for global changes)
- Frosted glass overlay using `PsgColors.glass(0.7)` etc.
- Subtle shadows via `PsgColors.glassShadow()`

**Key Components:**
- `PsgGlassAppBar` — Scroll-aware app bar that animates transparency based on scroll offset
- `GlassCard` — Frosted card container
- `MeshBackground` — Animated gradient mesh (all student/warden/admin screens use this)

---

## 🔐 AUTHENTICATION & ROLES

### **User Roles**
```dart
enum UserRole { student, warden, admin }

extension UserRoleExtension on UserRole {
  String get value => 'student' | 'warden' | 'admin';
  static UserRole? fromString(String? value) => ...
}
```

### **Auth Flow**
1. **Login**: Student enters roll number → `rollNumber@psgtech.ac.in`, Warden/Admin use email
2. **Firebase Auth**: Custom auth tokens with `role` stored in Firestore `users/{uid}.role`
3. **AuthProviderController**: Global provider that holds current user, role, and auth state
4. **GoRouter Guards**: Redirect based on role (student→/student, warden→/warden, admin→/admin)

### **Firestore Security**
- Roles are **authoritative** in `users/{uid}.role` (not just custom claims)
- Firestore rules prioritize `users/{uid}.role` for authorization checks
- Custom claims used as **fallback only** (to avoid stale-claim lockouts)

---

## 📊 KEY FEATURES & DATA MODELS

### **1. Student Dashboard & Profile**
- **Provider:** `StudentProfileProvider` (real-time Firestore stream)
- **Data:** name, email, rollNumber, programme, yearOfStudy, hostelName, blockName, roomNumber, roomType, floor, joiningDate, contactPhone, fatherName, primaryMobile, secondaryMobile, bloodGroup, address, balance, messType, messSupervisors, establishment, deposit
- **Screens:**
  - `StudentDashboardScreen` — Home with quick actions, mess info, fees summary, notices
  - `StudentProfileScreen` — Academic, hostel, contact details with copy-to-clipboard
  - `StudentRoomScreen` — Room information & guidelines
  - `StudentContactScreen` — Emergency contacts

### **2. Leave Requests**
- **Model:** `LeaveRequest` (domain entity)
- **States:** Pending, Approved, Rejected (with rejection reason, rejectedBy, rejectedAt, approvedBy, approvedAt)
- **Repository:** `LeaveRequestRepository` + `FirestoreLeaveRequestRepository`
- **Controller:** `LeaveRequestController` (ChangeNotifier)
- **Screens:**
  - `LeaveRequestScreen` — Student submit/view leave requests
  - `WardenLeaveRequestsScreen` — Warden approve/reject

### **3. Food Token System**
- **Model:** `FoodToken` (amount, scheduledDate, meal type, status)
- **Key Behavior:** 
  - **Per-item per-student aggregate limits** on selected day+meal (enforced in `book_token_screen.dart`)
  - **Expiry logic:** Tokens with `scheduledDate < today` are expired (hidden from Active list in `my_tokens_screen.dart`)
- **Repository:** `FoodTokenRepository` + `FirestoreFoodTokenRepository`
- **Inventory:** `FoodTokenInventoryRepository` (admin tracks available tokens)
- **Controllers:** `FoodTokenController`, `FoodTokenInventoryController`
- **Screens:**
  - `BookTokenScreen` — Students book tokens (with aggregate limit enforcement)
  - `MyTokensScreen` — View active/expired tokens

### **4. Warden Workflows**
- **Mess Management:** Approve/reject mess applications, manage meal supervisors
- **Leave Approvals:** Review & approve/reject student leave requests (records rejectionReason, rejectedBy, rejectedAt)
- **Complaints:** View student complaints, update status
- **Notices:** Post hostel-wide notices
- **Screens:** `WardenDashboardScreen`, `WardenMessApplicationsScreen`, `WardenLeaveRequestsScreen`, `WardenComplaintsScreen`, `WardenNoticeScreen`

### **5. Admin Dashboard**
- **User Management:** Assign roles, view statistics
- **Role Assignment:** Set/change user roles (admin → warden, student, etc.)
- **Room Allocation:** Manage room assignments
- **Food Token Inventory:** Configure available tokens per meal/day
- **Notices:** Post admin-level notices
- **Statistics:** Charts (occupancy, leave trends, mess stats)
- **Screens:** `AdminDashboardScreen`, `AdminRoleAssignmentScreen`, `AdminRoomAllocationScreen`, `AdminFoodTokenInventoryScreen`, `AdminStatisticsScreen`

### **6. Notifications**
- **Push Notifications:** Firebase Cloud Messaging for leave approvals, complaint updates
- **Local Notifications:** In-app reminders using `flutter_local_notifications`
- **Provider:** `NotificationProvider` (listens to Firestore, dispatches local notifications)

### **7. Complaints & Notices**
- **Complaints:** Students submit → Warden reviews & updates status
- **Notices:** Admin posts hostel-wide notices, students view in notices screen

---

## 🚀 STATE MANAGEMENT

### **Provider Pattern (ChangeNotifier + Consumer)**

All screens consume global/feature-level providers:

```dart
// Global providers (bootstrapped in main.dart)
Provider<ComplaintRepository>.value(value: complaintRepository)
ChangeNotifierProvider<StudentProfileProvider>(...)
ChangeNotifierProvider<LeaveRequestController>(...)
ChangeNotifierProvider<AuthProviderController>(...)
ChangeNotifierProvider<FoodTokenController>(...)
ChangeNotifierProvider<TShirtController>(...)
ChangeNotifierProvider<DayEntryController>(...)
ChangeNotifierProvider<NotificationProvider>(...)

// Usage in screens
Consumer<StudentProfileProvider>(builder: (context, profile, _) { ... })
context.read<AuthProviderController>().user
```

### **Scroll-Aware UI Optimization**

To avoid per-pixel rebuilds:
- Each screen maintains a `ScrollController` and `_scrollOffset` state variable
- Throttle updates to **8px delta** (skip small scroll changes)
- Pass offset to `PsgGlassAppBar` which animates blur/transparency

```dart
_scrollController.addListener(() {
  final nextOffset = _scrollController.offset;
  if ((nextOffset - _scrollOffset).abs() < 8) return;  // Throttle
  if (!mounted) return;
  setState(() => _scrollOffset = nextOffset);
});
```

---

## 🗄️ FIRESTORE COLLECTIONS

### **Key Collections & Schemas**

```
users/
  ├── {uid}
  │   ├── uid, name, email, role (authoritative)
  │   ├── roomId, createdAt, updatedAt
  │   ├── profile fields (rollNumber, programme, hostelName, etc.)
  │   ├── messType, establishment, deposit, balance

leave_requests/
  ├── {requestId}
  │   ├── studentUid, reason, dateFrom, dateTo, requestedAt
  │   ├── status (pending | approved | rejected)
  │   ├── rejectionReason, rejectedBy, rejectedAt
  │   ├── approvedBy, approvedAt

food_tokens/
  ├── {tokenId}
  │   ├── studentUid, mealType, scheduledDate, amount, status
  │   ├── createdAt

food_token_items/
  ├── {itemId} (admin-created inventory)
  │   ├── mealType, day, availableQuantity, createdAt

mess_applications/
  ├── {applicationId}
  │   ├── studentUid, messType, status, remarks
  │   ├── requestedAt, updatedAt

complaints/
  ├── {complaintId}
  │   ├── studentUid, category, description, attachments
  │   ├── status (open | resolved), createdAt, resolvedAt

notices/
  ├── {noticeId}
  │   ├── title, content, postedBy (adminUid), postedAt, priority

rooms/
  ├── {roomId}
  │   ├── number, type, floor, block, hostel, capacity, occupants

day_entries/
  ├── {entryId}
  │   ├── studentUid, date, status (present | absent | leave)
```

---

## 🔧 COMMON WORKFLOWS

### **Adding a New Feature Screen**

1. **Create feature module structure:**
   ```
   features/myfeature/
   ├── domain/
   │   ├── entities/my_entity.dart
   │   └── repositories/my_repository.dart
   ├── data/
   │   ├── models/my_model.dart
   │   └── repositories/firestore_my_repository.dart
   └── presentation/
       ├── controllers/my_controller.dart
       ├── pages/
       │   ├── student/my_feature_screen.dart
       │   ├── warden/warden_my_feature_screen.dart
       │   └── admin/admin_my_feature_screen.dart
       └── widgets/my_feature_widget.dart
   ```

2. **Use PsgDesignSystem for styling:**
   ```dart
   import 'package:hostel_app/core/design/psg_design_system.dart';
   
   Text('Title', style: PsgText.headline(28, color: PsgColors.primary))
   GlassCard(child: ...)
   PsgGlassAppBar(scrollOffset: _scrollOffset, ...)
   ```

3. **Bootstrap providers in main.dart:**
   ```dart
   ChangeNotifierProvider<MyController>(
     create: (_) => MyController(myRepository),
   ),
   ```

4. **Add routes to app_router.dart:**
   ```dart
   GoRoute(
     path: '/student/myfeature',
     pageBuilder: (context, state) => _buildPage(const MyFeatureScreen(), state),
   ),
   ```

### **Implementing Firestore Queries**

- Use `FirestoreService` for generic queries
- Create feature-specific `FirestoreXyzRepository` implementing domain repository
- Wrap Firestore calls in try-catch, emit errors to Provider

```dart
class FirestoreLeaveRequestRepository implements LeaveRequestRepository {
  @override
  Stream<List<LeaveRequest>> watchStudentLeaveRequests(String uid) {
    return FirebaseFirestore.instance
        .collection('leave_requests')
        .where('studentUid', isEqualTo: uid)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaveRequest.fromFirestore(doc))
            .toList());
  }
}
```

### **Scroll-Aware Glass App Bar Pattern**

All screens with scrollable content should use this pattern:

```dart
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final nextOffset = _scrollController.offset;
      if ((nextOffset - _scrollOffset).abs() < 8) return;
      if (!mounted) return;
      setState(() => _scrollOffset = nextOffset);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          scrollOffset: _scrollOffset,
          leading: IconButton(...),
        ),
        body: ListView(
          controller: _scrollController,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 88,
            bottom: 130,
            left: 24,
            right: 24,
          ),
          children: [...],
        ),
      ),
    );
  }
}
```

---

## ⚠️ KNOWN CONSTRAINTS & GOTCHAS

### **UI/Performance**
- `PsgGlassAppBar` does **NOT** expose a `bottom` parameter (unlike standard `AppBar`)
  - **Solution:** Place tab bars in the `body` below the app bar, not as app bar bottom
- Heavy `BackdropFilter` blur values cause jank
  - **Solution:** Tune blur/shadow params in `psg_design_system.dart` (global optimization, not per-feature)
- Per-pixel scroll rebuild is expensive
  - **Solution:** Throttle `_scrollOffset` updates by 8px delta (see scroll-aware pattern above)

### **Firebase/Firestore**
- If `firestore.rules` mapping is missing from `firebase.json`, production may use old/default rules → PERMISSION_DENIED on reads
  - **Solution:** Always include `firestore.rules` in firebase.json
- Composite index missing for `.where(...) + .orderBy(...)` queries on `notices` can fail silently
  - **Solution:** Use index-safe query + client-side filtering for immediate reliability (or wait for index creation)
- `food_token_items` missing `createdAt` field are excluded from `orderBy('createdAt')` results
  - **Solution:** Validate all docs have the field before deploying query

### **Auth & Security**
- If `UserRoleExtension` not imported in UI file, use `user.role.name` instead of extension method to avoid resolution errors
- Firestore rules must explicitly allow audit fields on leave rejections (rejectionReason, rejectedBy, rejectedAt, approvedBy, approvedAt)
  - **Solution:** Update firestore.rules to allow these keys for warden writes

### **Code Organization**
- `get_errors` returns many noise diagnostics from `code to replace/` folder
  - **Solution:** Validate app health with `flutter analyze` in `apps/hostel_app` for accurate signal
- Workspace is often dirty with unrelated changes
  - **Solution:** Limit edits to targeted files, avoid reverting unrelated diffs
- GitHub rejects push if >100MB file in local unpublished commits (even if later deleted)
  - **Solution:** `git reset --soft origin/main` → recommit → `git push --force-with-lease`

### **UI Implementation (In-Progress)**
- 6 new dashboard/form screens are in `code to replace/` folder pending integration
- They implement the glassmorphism design system and require smooth page transitions in app_router.dart
- Follow IMPLEMENTATION_GUIDE.md for step-by-step integration

---

## 📝 CURRENT WORK IN PROGRESS

### **Design System Integration** (`code to replace/`)
6 UI files created using the new PSG design system (glassmorphism, Manrope/Inter typography):

1. **psg_design_system.dart** — Centralized design tokens (colors, typography, theme)
2. **student_dashboard_screen.dart** — Student home with tabbed interface (Home/Mess/Fees/Notices/Profile)
3. **warden_dashboard_screen.dart** — Warden home with action cards
4. **admin_dashboard_screen.dart** — Admin home with quick stats
5. **leave_request_screen.dart** — Leave request form with reason input
6. **book_token_screen.dart** — Food token booking with date/meal selection

**Next Steps:**
- Copy design system file to `lib/core/design/`
- Replace existing dashboard screens with new versions
- Add smooth page transitions in app_router.dart (fade + slide)
- Test scroll-aware app bar transparency on all screens

---

## 🛠️ DEBUGGING & MAINTENANCE

### **Check App Health**
```bash
cd apps/hostel_app
flutter analyze                  # Accurate signal (ignores noise from code to replace/)
flutter pub get                  # Resolve dependencies
```

### **Firebase Deployment**
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Cloud Functions
firebase deploy --only functions
```

### **Common Issues**
1. **PERMISSION_DENIED on Firestore read** → Check firestore.rules in firebase.json
2. **Custom claims stale** → Regenerate via admin script or clear cache
3. **Notifications not working** → Verify Firebase Cloud Messaging is enabled in Firebase console
4. **Scroll jank** → Profile with DevTools, reduce blur/shadow in design system
5. **Role-based redirect loops** → Check GoRouter guards and Firestore `users/{uid}.role` field

---

## 📞 QUICK REFERENCE: When AI Asks Questions

When you provide code changes or ask for features, specify:

1. **Feature** — Which feature module (auth, dashboard, tokens, leave, etc.)
2. **Screen** — Which screen and role (StudentDashboardScreen, WardenLeaveRequestsScreen, etc.)
3. **Data Flow** — If new data, include Firestore collection schema
4. **Design** — Must use PsgDesignSystem (colors, typography, glass components)
5. **Constraints** — Any specific behavior (e.g., token expiry logic, aggregate limits)
6. **Testing** — How to validate the change (test roles, test offline, test with mock data)

---

## 🎓 GETTING AI UP TO SPEED

When starting a new conversation with AI:

**Paste this prompt** to help any AI understand:
- The project is a **production-ready Flutter hostel management system**
- Uses **clean architecture** with feature modules
- Implements **glassmorphic design system** (colors, typography, glass components in `psg_design_system.dart`)
- Has **role-based access** (Student/Warden/Admin) enforced at routing & feature level
- Uses **Firestore** for real-time data + **Provider** for state management
- Follow **scroll-aware UI pattern** for performance (throttle scroll updates by 8px delta)
- All new UI must use **PsgDesignSystem** (PsgColors, PsgText, PsgTheme, glass components)

---

## 📚 Key Files to Reference

| File | Purpose |
|------|---------|
| [lib/core/design/psg_design_system.dart](lib/core/design/psg_design_system.dart) | Design tokens, colors, typography, theme |
| [lib/main.dart](lib/main.dart) | Bootstrap, Firebase init, global providers |
| [lib/app/app.dart](lib/app/app.dart) | MaterialApp.router config, PsgTheme usage |
| [lib/app/app_router.dart](lib/app/app_router.dart) | Route map, auth guards, role-based redirects |
| [docs/folder_responsibilities.md](docs/folder_responsibilities.md) | Architecture overview |
| [code to replace/IMPLEMENTATION_GUIDE.md](code to replace/IMPLEMENTATION_GUIDE.md) | Design system integration steps |
| [code to replace/psg_design_system.dart](code to replace/psg_design_system.dart) | New design system file to integrate |

---

## 🎯 SUMMARY FOR AI

You are working on a **production-ready Flutter hostel management application** with:

✅ Feature-first clean architecture  
✅ Role-based access control (Student/Warden/Admin)  
✅ Glassmorphic Material Design 3 UI  
✅ Real-time Firestore data sync  
✅ Provider-based state management  
✅ Scroll-aware performance optimization  

**Core Constraints:**
- Use `PsgDesignSystem` for all UI
- Throttle scroll updates (8px delta)
- Prioritize Firestore `users/{uid}.role` over custom claims
- Store audit fields in Firestore (rejectionReason, approvedBy, etc.)
- No `bottom` parameter on `PsgGlassAppBar` (use body instead)

**When you need changes:**
1. State the feature + screen + role
2. Reference the Firestore schema if data-related
3. Use PsgDesignSystem for styling
4. Follow scroll-aware pattern for scrollable screens
5. Test with different roles (student, warden, admin)

---

**Questions? Ask with specific context (screen name, feature, Firestore collection, etc.) and this prompt ensures AI has full project knowledge.**
