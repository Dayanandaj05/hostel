import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';

const _kNavy = Color(0xFF0D2137);
const _kTeal = Color(0xFF009688);
const _kBreakpoint = 700.0;

// ─────────────────────────────────────────────────────────────────────────────
// Login Screen  –  Student / Warden / Admin tabs
// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _kBreakpoint;
          if (wide) {
            return Row(
              children: [
                Expanded(child: _BrandPanel()),
                Expanded(child: _formPanel()),
              ],
            );
          }
          return Column(
            children: [
              _CompactHeader(),
              Expanded(child: _formPanel()),
            ],
          );
        },
      ),
    );
  }

  Widget _formPanel() {
    return Column(
      children: [
        // Role selector tabs
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: _kNavy,
            unselectedLabelColor: Colors.grey,
            indicatorColor: _kTeal,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Student'),
              Tab(text: 'Warden'),
              Tab(text: 'Admin'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _StudentLoginForm(),
              _StaffLoginForm(role: _StaffRole.warden),
              _StaffLoginForm(role: _StaffRole.admin),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STUDENT LOGIN  (roll number → email@psgtech.hostel)
// ─────────────────────────────────────────────────────────────────────────────
class _StudentLoginForm extends StatefulWidget {
  const _StudentLoginForm();
  @override
  State<_StudentLoginForm> createState() => _StudentLoginFormState();
}

class _StudentLoginFormState extends State<_StudentLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _rollController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _showBanner = true;
  String? _error;

  @override
  void dispose() {
    _rollController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _toEmail(String roll) {
    final input = roll.trim().toLowerCase();
    return input.contains('@') ? input : '$input@psgtech.hostel';
  }

  Future<void> _signIn(AuthProviderController auth) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final success = await auth.signInWithEmailAndPassword(
      email: _toEmail(_rollController.text),
      password: _passwordController.text,
    );
    if (!success && mounted) {
      setState(() => _error = auth.errorMessage ?? 'Sign-in failed.');
    }
  }

  Future<void> _forgotPassword(AuthProviderController auth) async {
    final roll = _rollController.text.trim();
    if (roll.isEmpty) {
      setState(() => _error = 'Enter your Roll Number first.');
      return;
    }
    await auth.sendPasswordResetEmail(_toEmail(roll));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent if account exists.')),
      );
    }
  }

  Future<void> _seedStudent(AuthProviderController auth) async {
    setState(() => _error = '⏳ Seeding student account...');
    const email = '25mx308@psgtech.hostel';
    const password = 'password123';
    String? uid;
    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      uid = cred.user?.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'INVALID_LOGIN_CREDENTIALS') {
        try {
          final cred = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password);
          uid = cred.user?.uid;
        } catch (ce) {
          if (mounted) setState(() => _error = 'Seed failed: $ce');
          return;
        }
      } else {
        if (mounted) setState(() => _error = 'Seed failed: ${e.message}');
        return;
      }
    }
    if (uid == null) {
      if (mounted) setState(() => _error = 'Seed failed: no UID');
      return;
    }
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
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (!mounted) return;
    final success = await auth.signInWithEmailAndPassword(
      email: email, password: password);
    if (mounted) {
      if (success) {
        _rollController.text = '25MX308';
        _passwordController.text = 'password123';
        setState(() => _error = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Student account seeded!')),
        );
      } else {
        setState(() => _error = auth.errorMessage ?? 'Seed OK but login failed.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProviderController>(
      builder: (context, auth, _) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_showBanner) _infoBanner(),
              _heading('Student Sign In', 'Enter your roll number and password'),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _rollController,
                      enabled: !auth.isLoading,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Roll Number',
                        hintText: 'e.g. 24MCA001',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Roll number required';
                        if (v.trim().length < 5) return 'Min 5 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _passwordField(_passwordController, auth.isLoading,
                        () => setState(() => _obscure = !_obscure), _obscure),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: auth.isLoading ? null : () => _forgotPassword(auth),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    _signInButton(auth, () => _signIn(auth)),
                    if (_error != null) _errorBox(_error!),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: auth.isLoading ? null : () => _seedStudent(auth),
                child: const Text('Seed Test Student (25MX308 / password123)',
                    style: TextStyle(fontSize: 12)),
              ),
              _helpText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade800, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Students can apply for North Indian Mess in the Mess Details section after login.',
              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _showBanner = false),
            child: Icon(Icons.close, size: 16, color: Colors.amber.shade800),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WARDEN / ADMIN LOGIN  (email + password)
// ─────────────────────────────────────────────────────────────────────────────
enum _StaffRole { warden, admin }

class _StaffLoginForm extends StatefulWidget {
  const _StaffLoginForm({required this.role});
  final _StaffRole role;
  @override
  State<_StaffLoginForm> createState() => _StaffLoginFormState();
}

class _StaffLoginFormState extends State<_StaffLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isAdmin => widget.role == _StaffRole.admin;
  String get _roleLabel => _isAdmin ? 'Admin' : 'Warden';
  String get _roleValue => _isAdmin ? 'admin' : 'warden';
  // Seed credentials
  String get _seedEmail =>
      _isAdmin ? 'admin@psgtech.hostel' : 'warden@psgtech.hostel';
  String get _seedPassword => _isAdmin ? 'admin123456' : 'warden123456';
  String get _seedName => _isAdmin ? 'Hostel Admin' : 'Block Warden';

  Future<void> _signIn(AuthProviderController auth) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final success = await auth.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!success && mounted) {
      // Extra guard: if the account exists but has a different role,
      // show a clear message instead of a generic error.
      final msg = auth.errorMessage ?? 'Sign-in failed.';
      setState(() => _error = msg);
    }
  }

  Future<void> _forgotPassword(AuthProviderController auth) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    await auth.sendPasswordResetEmail(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent if account exists.')),
      );
    }
  }

  Future<void> _seedAccount(AuthProviderController auth) async {
    setState(() => _error = '⏳ Seeding $_roleLabel account...');
    String? uid;
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _seedEmail, password: _seedPassword);
      uid = cred.user?.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'INVALID_LOGIN_CREDENTIALS') {
        try {
          final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: _seedEmail, password: _seedPassword);
          uid = cred.user?.uid;
        } catch (ce) {
          if (mounted) setState(() => _error = 'Seed failed: $ce');
          return;
        }
      } else {
        if (mounted) setState(() => _error = 'Seed failed: ${e.message}');
        return;
      }
    }
    if (uid == null) {
      if (mounted) setState(() => _error = 'Seed failed: no UID');
      return;
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': _seedName,
      'email': _seedEmail,
      'role': _roleValue,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (!mounted) return;
    final success = await auth.signInWithEmailAndPassword(
        email: _seedEmail, password: _seedPassword);
    if (mounted) {
      if (success) {
        _emailController.text = _seedEmail;
        _passwordController.text = _seedPassword;
        setState(() => _error = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ $_roleLabel account seeded!')),
        );
      } else {
        setState(() =>
            _error = auth.errorMessage ?? 'Seed OK but login failed.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProviderController>(
      builder: (context, auth, _) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Role badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isAdmin
                        ? Colors.deepPurple.withValues(alpha: 0.1)
                        : _kNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isAdmin
                          ? Colors.deepPurple.withValues(alpha: 0.4)
                          : _kNavy.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isAdmin
                            ? Icons.admin_panel_settings_rounded
                            : Icons.manage_accounts_rounded,
                        size: 16,
                        color: _isAdmin ? Colors.deepPurple : _kNavy,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_roleLabel Portal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _isAdmin ? Colors.deepPurple : _kNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _heading('$_roleLabel Sign In',
                  'Use your institutional email address'),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      enabled: !auth.isLoading,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: _isAdmin
                            ? 'e.g. admin@psgtech.hostel'
                            : 'e.g. warden@psgtech.hostel',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _passwordField(_passwordController, auth.isLoading,
                        () => setState(() => _obscure = !_obscure), _obscure),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: auth.isLoading
                            ? null
                            : () => _forgotPassword(auth),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    _signInButton(auth, () => _signIn(auth),
                        label: 'Sign In as $_roleLabel'),
                    if (_error != null) _errorBox(_error!),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Seed button (dev helper)
              OutlinedButton.icon(
                onPressed: auth.isLoading ? null : () => _seedAccount(auth),
                icon: const Icon(Icons.build_circle_outlined, size: 16),
                label: Text(
                    'Seed Test $_roleLabel ($_seedEmail / $_seedPassword)',
                    style: const TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  side: BorderSide(color: Colors.grey.shade300),
                  minimumSize: const Size(double.infinity, 36),
                ),
              ),
              _helpText(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

Widget _heading(String title, String subtitle) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: _kNavy)),
      const SizedBox(height: 4),
      Text(subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
    ],
  );
}

Widget _passwordField(TextEditingController controller, bool loading,
    VoidCallback toggleObscure, bool obscure) {
  return TextFormField(
    controller: controller,
    enabled: !loading,
    obscureText: obscure,
    decoration: InputDecoration(
      labelText: 'Password',
      prefixIcon: const Icon(Icons.lock_outline),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      suffixIcon: IconButton(
        icon: Icon(obscure
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined),
        onPressed: toggleObscure,
      ),
    ),
    validator: (v) {
      if (v == null || v.isEmpty) return 'Password required';
      if (v.length < 6) return 'Minimum 6 characters';
      return null;
    },
  );
}

Widget _signInButton(AuthProviderController auth, VoidCallback onPressed,
    {String label = 'Sign In'}) {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: SizedBox(
      height: 50,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _kNavy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: auth.isLoading ? null : onPressed,
        child: auth.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    ),
  );
}

Widget _errorBox(String message) {
  return Container(
    margin: const EdgeInsets.only(top: 14),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
        ),
      ],
    ),
  );
}

Widget _helpText() {
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Center(
      child: Text('Need help? Contact hostel office',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BRAND PANEL  (wide screens — left side)
// ─────────────────────────────────────────────────────────────────────────────
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
              const _PsgDiamondLogo(size: 90),
              const SizedBox(height: 24),
              const Text(
                'PSG INSTITUTIONS',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5),
              ),
              const SizedBox(height: 6),
              Text(
                'Resident Portal',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 15,
                    letterSpacing: 1),
              ),
              const SizedBox(height: 40),
              ...[
                _bullet(Icons.school_rounded, 'Student self-service portal'),
                _bullet(Icons.manage_accounts_rounded, 'Warden management tools'),
                _bullet(Icons.admin_panel_settings_rounded, 'Admin controls & analytics'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _bullet(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _kTeal, size: 18),
          const SizedBox(width: 10),
          Text(text,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT HEADER  (mobile — top strip)
// ─────────────────────────────────────────────────────────────────────────────
class _CompactHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: const BoxDecoration(
        color: _kNavy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _PsgDiamondLogo(size: 52),
            const SizedBox(height: 12),
            const Text('PSG INSTITUTIONS',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2)),
            const SizedBox(height: 3),
            Text('Resident Portal',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PSG DIAMOND LOGO
// ─────────────────────────────────────────────────────────────────────────────
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
          angle: 0.7854,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _kTeal,
              borderRadius: BorderRadius.circular(size * 0.16),
              boxShadow: [
                BoxShadow(
                    color: _kTeal.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Center(
              child: Transform.rotate(
                angle: -0.7854,
                child: Text(
                  'PSG',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
