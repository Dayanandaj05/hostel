import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_app/services/notifications/notification_service.dart';

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

  // isAuthenticated is true ONLY when we also have the user's role from Firestore.
  // This prevents the router from redirecting to /unauthorized while the user
  // doc is still being fetched.
  bool get isAuthenticated => _user != null;
  UserRole? get role => _user?.role;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_authService.currentUser != null) {
        _user = await _authService.getCurrentUserModel();
      } else {
        // No authenticated user — leave _user as null.
        // GoRouter redirect will send unauthenticated users to /login.
      }
    } catch (e) {
      _errorMessage = 'Failed to load user: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Keep user model in sync with Firestore changes.
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

      // Fetch the full user model before notifying — ensures router sees a
      // complete state (isAuthenticated && role != null) in one go.
      if (credential.user != null) {
        _user = await _authService.getCurrentUserModel();
        if (_user != null) {
          await NotificationService.updateToken(_user!.uid);
          await NotificationService.subscribeToRole(_user!.role.name);
        }
      }
      return credential.user != null;
    } on AuthServiceException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Sign-up failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners(); // Single notification after everything is resolved.
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

      // Fetch the full user model before notifying — ensures router sees a
      // complete state (isAuthenticated && role != null) in one go.
      if (credential.user != null) {
        _user = await _authService.getCurrentUserModel();
        if (_user != null) {
          await NotificationService.updateToken(_user!.uid);
          await NotificationService.subscribeToRole(_user!.role.name);
        }
      }
      return credential.user != null && _user != null;
    } on AuthServiceException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Sign-in failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners(); // Single notification after everything is resolved.
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await NotificationService.unsubscribeAll();
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
