import 'dart:ui';

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
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutQuart),
        );
    _entryController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _FrostedBackdrop(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width >= _kBreakpoint
                        ? 760
                        : 560,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _glassShell(_formPanel()),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassShell(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.75),
                Colors.white.withValues(alpha: 0.55),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF003F87).withValues(alpha: 0.15),
                blurRadius: 48,
                offset: const Offset(0, 24),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(-1, -1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _formPanel() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const _CompactHeader(),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: 1,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF003F87),
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: const Color(0xFF001F54),
                  indicatorWeight: 3.5,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: '👤 Student'),
                    Tab(text: '🔒 Warden'),
                    Tab(text: '⚙️ Admin'),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
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
// STUDENT LOGIN  (roll number → email@psgtech.ac.in)
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
    return input.contains('@') ? input : '$input@psgtech.ac.in';
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
        const SnackBar(
          content: Text('Password reset email sent if account exists.'),
        ),
      );
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
              _heading(
                'Student Sign In',
                'Enter your roll number and password',
              ),
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
                        hintText: 'e.g. 25MX308',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Roll number required';
                        }
                        if (v.trim().length < 5) {
                          return 'Min 5 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _passwordField(
                      _passwordController,
                      auth.isLoading,
                      () => setState(() => _obscure = !_obscure),
                      _obscure,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: auth.isLoading
                            ? null
                            : () => _forgotPassword(auth),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    _signInButton(auth, () => _signIn(auth)),
                    if (_error != null) _errorBox(_error!),
                  ],
                ),
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
        const SnackBar(
          content: Text('Password reset email sent if account exists.'),
        ),
      );
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
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
              _heading(
                '$_roleLabel Sign In',
                'Use your institutional email address',
              ),
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
                            ? 'e.g. admin@psgtech.ac.in'
                            : 'e.g. warden@psgtech.ac.in',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email required';
                        }
                        if (!v.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _passwordField(
                      _passwordController,
                      auth.isLoading,
                      () => setState(() => _obscure = !_obscure),
                      _obscure,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: auth.isLoading
                            ? null
                            : () => _forgotPassword(auth),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    _signInButton(
                      auth,
                      () => _signIn(auth),
                      label: 'Sign In as $_roleLabel',
                    ),
                    if (_error != null) _errorBox(_error!),
                  ],
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
      Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _kNavy,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
    ],
  );
}

Widget _passwordField(
  TextEditingController controller,
  bool loading,
  VoidCallback toggleObscure,
  bool obscure,
) {
  return TextFormField(
    controller: controller,
    enabled: !loading,
    obscureText: obscure,
    decoration: InputDecoration(
      labelText: 'Password',
      prefixIcon: const Icon(Icons.lock_outline),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
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

Widget _signInButton(
  AuthProviderController auth,
  VoidCallback onPressed, {
  String label = 'Sign In',
}) {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: SizedBox(
      height: 50,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _kNavy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: auth.isLoading ? null : onPressed,
        child: auth.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
          child: Text(
            message,
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

Widget _helpText() {
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Center(
      child: Text(
        'Need help? Contact hostel office',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT HEADER  (mobile — top strip)
// ─────────────────────────────────────────────────────────────────────────────
class _CompactHeader extends StatelessWidget {
  const _CompactHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _PsgDiamondLogo(size: 52),
        const SizedBox(height: 10),
        const Text(
          'PSG INSTITUTIONS',
          style: TextStyle(
            color: _kNavy,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Resident Portal',
          style: TextStyle(color: _kNavy.withValues(alpha: 0.7), fontSize: 12),
        ),
      ],
    );
  }
}

class _FrostedBackdrop extends StatelessWidget {
  const _FrostedBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6F4FF), Color(0xFFDDF3FF), Color(0xFFF3FAFF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -40,
            child: _hueBlob(const Color(0xFF8ED3FF), 220),
          ),
          Positioned(
            bottom: -90,
            right: -50,
            child: _hueBlob(const Color(0xFFBEE9FF), 260),
          ),
          Positioned(
            top: 220,
            right: 30,
            child: _hueBlob(const Color(0xFFA6DCFF), 140),
          ),
        ],
      ),
    );
  }

  Widget _hueBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.45),
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
                  offset: const Offset(0, 6),
                ),
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
