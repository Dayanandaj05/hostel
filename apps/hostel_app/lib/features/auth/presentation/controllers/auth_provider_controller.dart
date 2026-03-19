import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthProviderController extends ChangeNotifier {
  AuthProviderController(this._authService) : _user = null;

  final AuthService _authService;
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  UserRole? get role => _user?.role;

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_authService.currentUser != null) {
        _user = await _authService.getCurrentUserModel();
      }
    } catch (e) {
      _errorMessage = 'Failed to load user: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    _authService.watchCurrentUserModel().listen((userModel) {
      _user = userModel;
      notifyListeners();
    });
  }

  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      _user = await _authService.getCurrentUserModel();
      notifyListeners();
      return credential.user != null;
    } on AuthServiceException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Sign-up failed: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = await _authService.getCurrentUserModel();
      notifyListeners();
      return credential.user != null;
    } on AuthServiceException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Sign-in failed: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _errorMessage = 'Sign-out failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _errorMessage = 'Check your email for password reset link.';
    } on AuthServiceException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to send reset email: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  static AuthProviderController of(BuildContext context) {
    return context.read<AuthProviderController>();
  }
}
