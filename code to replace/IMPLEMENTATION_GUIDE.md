# ──────────────────────────────────────────────────────────────────────────────
# PSG HOSTEL  —  Implementation Instructions
# ──────────────────────────────────────────────────────────────────────────────

## STEP 1 — Add google_fonts to pubspec.yaml

Under `dependencies:` add:
  google_fonts: ^6.2.1

Then run:
  flutter pub get


## STEP 2 — Copy the 6 Dart files

Copy each output file into the matching path inside your project:

  outputs/lib/core/design/psg_design_system.dart
    → lib/core/design/psg_design_system.dart           (NEW FOLDER)

  outputs/lib/features/dashboard/…/student/student_dashboard_screen.dart
    → lib/features/dashboard/presentation/pages/student/student_dashboard_screen.dart (REPLACE)

  outputs/lib/features/dashboard/…/warden/warden_dashboard_screen.dart
    → lib/features/dashboard/presentation/pages/warden/warden_dashboard_screen.dart (REPLACE)

  outputs/lib/features/dashboard/…/admin/admin_dashboard_screen.dart
    → lib/features/dashboard/presentation/pages/admin/admin_dashboard_screen.dart (REPLACE)

  outputs/lib/features/leave/…/leave_request_screen.dart
    → lib/features/leave/presentation/pages/student/leave_request_screen.dart (REPLACE)

  outputs/lib/features/tokens/…/book_token_screen.dart
    → lib/features/tokens/presentation/pages/student/book_token_screen.dart (REPLACE)


## STEP 3 — Update app/app.dart (use PsgTheme)

Replace the MaterialApp.router theming block:

  MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'Hostel Management System',
    theme: PsgTheme.light,          // ← PsgTheme from design system
    themeMode: ThemeMode.light,     // ← lock to light for now
    routerConfig: _router,
  );

Add the import at the top:
  import '../core/design/psg_design_system.dart';


## STEP 4 — Smooth page transitions in app_router.dart

Replace every:
  builder: (_, __) => const SomePage()

with:
  pageBuilder: (_, state, child) => CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, anim, _, w) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: w,
      ),
    ),
    transitionDuration: const Duration(milliseconds: 300),
  ),

To use `pageBuilder` the route must be `GoRoute(path:…, pageBuilder: …)`.


## STEP 5 — Scroll-aware transparency (already in screens)

Each new screen creates a ScrollController and passes its offset to PsgGlassAppBar.
The app bar uses BackdropFilter + AnimatedContainer to animate between:
  - transparent + no blur (offset = 0)
  - 40% white glass + blur 40 (offset ≥ 60px)

No extra work needed — it's wired up in every screen.


## STEP 6 — Staggered entry animations (already in screens)

Wrap any new widget you add in:
  StaggeredEntry(index: N, child: yourWidget)

N determines the delay (N × 60ms base). Set index=0 for first item.


## STEP 7 — Screens NOT yet converted

These screens still use the old dark navy theme.
Apply the same pattern: add MeshBackground, PsgGlassAppBar, GlassCard, PsgBottomNav.

  - warden_leave_requests_screen.dart
  - warden_mess_applications_screen.dart
  - warden_complaints_screen.dart
  - complaint_submission_screen.dart
  - tshirt_screen.dart
  - day_entry_screen.dart
  - student_profile_screen.dart
  - admin_statistics_screen.dart
  - admin_notice_post_screen.dart
  - admin_hostel_day_screen.dart

Pattern to follow for every unconverted screen:

  class _YourScreenState extends State<YourScreen>
      with SingleTickerProviderStateMixin {

    final _scrollController = ScrollController();
    double _scrollOffset = 0;
    late AnimationController _entryController;
    late Animation<double> _fadeAnim;
    late Animation<Offset> _slideAnim;

    @override
    void initState() {
      super.initState();
      _scrollController.addListener(
          () => setState(() => _scrollOffset = _scrollController.offset));
      _entryController = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500));
      _fadeAnim = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
      _slideAnim = Tween<Offset>(
              begin: const Offset(0, 0.05), end: Offset.zero)
          .animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));
      _entryController.forward();
    }

    @override
    Widget build(BuildContext context) {
      return MeshBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: PsgGlassAppBar(scrollOffset: _scrollOffset),
          body: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 88,
                  bottom: 60, left: 24, right: 24,
                ),
                children: [
                  // Your content here, wrapped in StaggeredEntry(index: N)
                ],
              ),
            ),
          ),
        ),
      );
    }
  }


## STEP 8 — Run the app

  flutter run

If you see "BackdropFilter not rendering blur on Android emulator",
ensure you are using a physical device or enable GPU in the emulator:
  Extended Controls → OpenGL ES renderer → set to swiftshader_indirect


## Design token cheatsheet

  PsgColors.primary            #003F87  (deep blue)
  PsgColors.primaryContainer   #0056B3  (mid blue)
  PsgColors.secondary          #366288  (steel blue)
  PsgColors.green              #15803D
  PsgColors.error              #BA1A1A
  PsgColors.onSurfaceVariant   #424752  (muted label text)

  PsgText.headline(size)       Manrope, weight 900
  PsgText.body(size)           Inter, weight 400
  PsgText.label(size)          Inter, weight 700 + letter spacing

  GlassCard(child:…)           40% white glass + blur 40
  MeshBackground(child:…)      radial gradient blobs
  PsgGlassAppBar(scrollOffset:…) scroll-reactive app bar
  PsgBottomNav(…)              animated pill nav bar
  StaggeredEntry(index:…)      staggered fade+slide in
  PsgFilledButton(…)           gradient CTA button
  PsgStatusChip.approved()     green chip
  PsgStatusChip.pending()      amber chip
  PsgStatusChip.rejected()     red chip
  PsgAvatarInitials(name:…)    initials circle avatar
