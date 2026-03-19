import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/user_model.dart';
import '../../controllers/auth_provider_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isSignUpMode = false;
  late final TextEditingController _nameController;
  UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(AuthProviderController authProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text;
    final password = _passwordController.text;

    if (_isSignUpMode) {
      final name = _nameController.text;
      final role = _selectedRole ?? UserRole.student;

      final success = await authProvider.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-up successful!')),
        );
      }
    } else {
      final success = await authProvider.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(authProvider.errorMessage ?? 'Sign-in failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Consumer<AuthProviderController>(
            builder: (context, authProvider, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hostel Management',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSignUpMode ? 'Create an Account' : 'Welcome Back',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      if (authProvider.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    authProvider.errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_isSignUpMode)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_isSignUpMode)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: DropdownButtonFormField<UserRole>(
                            value: _selectedRole ?? UserRole.student,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                              prefixIcon: Icon(Icons.security),
                            ),
                            items: UserRole.values
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role.value.toUpperCase()),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedRole = value);
                            },
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : () => _handleSubmit(authProvider),
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isSignUpMode ? 'Create Account' : 'Sign In',
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () {
                                _formKey.currentState?.reset();
                                _emailController.clear();
                                _passwordController.clear();
                                _nameController.clear();
                                authProvider.clearError();
                                setState(() => _isSignUpMode = !_isSignUpMode);
                              },
                        child: Text(
                          _isSignUpMode
                              ? 'Already have an account? Sign In'
                              : 'Don\'t have an account? Sign Up',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
