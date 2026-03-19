import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_app/features/auth/domain/entities/user_model.dart';
import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PSG Hostel – Login Screen
// ─────────────────────────────────────────────────────────────────────────────

const _kNavy = Color(0xFF0D2137);
const _kTeal = Color(0xFF009688);
const _kBreakpoint = 700.0;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rollController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _showBanner = true;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _rollController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _rollController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Auth helpers ──────────────────────────────────────────────────────────

  String _buildEmail(String roll) => '${roll.trim().toLowerCase()}@psgtech.hostel';

  Future<void> _handleSignIn(AuthProviderController auth) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _inlineError = null);

    final email = _buildEmail(_rollController.text);
    final password = _passwordController.text;

    final success = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (!success && mounted) {
      setState(() {
        _inlineError = auth.errorMessage ?? 'Sign-in failed. Please try again.';
      });
    }
    // On success GoRouter redirects automatically — no manual navigation.
  }

  Future<void> _handleForgotPassword(AuthProviderController auth) async {
    final roll = _rollController.text.trim();
    if (roll.isEmpty) {
      setState(() => _inlineError = 'Enter your Roll Number first.');
      return;
    }
    await auth.sendPasswordResetEmail(_buildEmail(roll));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('If an account exists, a password-reset link was sent.'),
        ),
      );
    }
  }

  Future<void> _seedTestUser(AuthProviderController auth) async {
    setState(() => _inlineError = 'Seeding test user...');
    try {
      final email = '25mx308@psgtech.hostel';
      final password = 'password123';

      // 1. Create Auth User or Sign In if exists
      bool success = false;
      try {
        success = await auth.signUpWithEmailAndPassword(
          email: email,
          password: password,
          name: 'Test Student',
          role: UserRole.student,
        );
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          // If already exists, sign in to ensure we have the UID
          success = await auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      if (success) {
        final uid = auth.user?.uid;
        if (uid != null) {
          // 2. Add extra profile fields to Firestore
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'name': 'Test Student',
            'email': email,
            'role': 'student',
            'rollNumber': '25MX308',
            'programme': 'MASTER OF COMPUTER APPLICATIONS',
            'yearOfStudy': '1st Year, 2025 Batch',
            'contactPhone': '+91 9876543210',
            'fatherName': 'PSG Father',
            'address': 'PSG Hostel, Avinashi Road, Coimbatore',
            'primaryMobile': '+91 9876543210',
            'secondaryMobile': '+91 9876543211',
            'establishment': 50000,
            'deposit': 5000,
            'balance': 39447,
            'hostelName': 'Main Hostel',
            'blockName': 'G3 Block',
            'roomType': 'New 4 In 1 Room',
            'floor': 'Fifth Floor',
            'roomNumber': 'G3-621',
            'joiningDate': '04-AUG-25',
            'messName': 'G Mess',
            'messType': 'South Indian',
            'messSupervisors': ['Supervisor 1', 'Supervisor 2'],
            'eggToken': true,
            'nonVegToken': false,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Test user 25MX308 created/updated!')),
            );
            _rollController.text = '25MX308';
            _passwordController.text = 'password123';
            setState(() => _inlineError = null);
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _inlineError = 'Seed failed: $e');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProviderController>(
        builder: (context, auth, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= _kBreakpoint;

              if (wide) {
                return Row(
                  children: [
                    Expanded(child: _BrandPanel()),
                    Expanded(
                      child: _formSide(auth),
                    ),
                  ],
                );
              }

              // Narrow / mobile
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _CompactHeader(),
                    _formSide(auth),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _formSide(AuthProviderController auth) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Info banner ──
              if (_showBanner) _infoBanner(),

              const SizedBox(height: 8),

              Text(
                'Sign In',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Use your institution roll number',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),

              const SizedBox(height: 28),

              // ── Form ──
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Roll Number
                    TextFormField(
                      controller: _rollController,
                      enabled: !auth.isLoading,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Roll Number',
                        hintText: 'e.g. 24MCA001',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Roll number is required';
                        }
                        if (v.trim().length < 5) {
                          return 'Enter a valid roll number (min 5 chars)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      enabled: !auth.isLoading,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(
                                () => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 6) {
                          return 'Must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 4),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed:
                            auth.isLoading ? null : () => _handleForgotPassword(auth),
                        child: const Text('Forgot Password?'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Sign In button
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _kNavy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed:
                            auth.isLoading ? null : () => _handleSignIn(auth),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),

                    // ── Inline error ──
                    if (_inlineError != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _inlineError!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Seeding button (Temporary)
              TextButton(
                onPressed: auth.isLoading ? null : () => _seedTestUser(auth),
                child: const Text('Seed Test Student Account (25MX308)'),
              ),

              const SizedBox(height: 12),

              // Help text
              Center(
                child: Text(
                  'Need help? Contact hostel office',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Info banner ───────────────────────────────────────────────────────────

  Widget _infoBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // amber‑50
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Students are instructed to utilize the online North Indian '
              'mess application feature available in Mess Details section '
              'post-login.',
              style: TextStyle(fontSize: 12.5, color: Colors.amber.shade900),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _showBanner = false),
            child: Icon(Icons.close, size: 18, color: Colors.amber.shade800),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LEFT BRAND PANEL (wide screens)
// ═════════════════════════════════════════════════════════════════════════════

class _BrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kNavy,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Diamond Logo ──
              const _PsgDiamondLogo(size: 90),

              const SizedBox(height: 24),

              const Text(
                'PSG INSTITUTIONS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Resident Portal',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 36),

              // ── Bullet points ──
              ..._bulletPoints.map(
                (text) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: _kTeal, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        text,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _bulletPoints = [
    'Manage your hostel life',
    'Apply leave digitally',
    'Track mess & fees',
  ];
}

// ═════════════════════════════════════════════════════════════════════════════
// COMPACT HEADER (narrow / mobile screens)
// ═════════════════════════════════════════════════════════════════════════════

class _CompactHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: const BoxDecoration(
        color: _kNavy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _PsgDiamondLogo(size: 56),
            const SizedBox(height: 14),
            const Text(
              'PSG INSTITUTIONS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Resident Portal',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PSG DIAMOND LOGO (Flutter widget – rotated rounded square with "PSG" text)
// ═════════════════════════════════════════════════════════════════════════════

class _PsgDiamondLogo extends StatelessWidget {
  const _PsgDiamondLogo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.3,
      height: size * 1.3,
      child: Center(
        child: Transform.rotate(
          angle: 0.7854, // 45° in radians
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _kTeal,
              borderRadius: BorderRadius.circular(size * 0.16),
              boxShadow: [
                BoxShadow(
                  color: _kTeal.withOpacity(0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Transform.rotate(
                angle: -0.7854, // rotate text back
                child: Text(
                  'PSG',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
