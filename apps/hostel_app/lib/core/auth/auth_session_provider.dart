import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum UserRole { student, warden, admin }

class AuthSessionProvider extends ChangeNotifier {
  bool _isInitialized = false;
  String? _userId;
  UserRole? _role;

  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _userId != null;
  String? get userId => _userId;
  UserRole? get role => _role;

  Future<void> initialize() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> signInAs(UserRole role) async {
    _userId = 'dev-user';
    _role = role;
    notifyListeners();
  }

  Future<void> signOut() async {
    _userId = null;
    _role = null;
    notifyListeners();
  }

  static AuthSessionProvider of(BuildContext context) {
    return context.read<AuthSessionProvider>();
  }
}
