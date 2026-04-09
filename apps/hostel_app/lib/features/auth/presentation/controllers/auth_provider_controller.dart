import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_app/services/notifications/notification_service.dart';

import '../../domain/entities/user_model.dart';
import '../../../../services/auth/auth_service.dart';

class AuthProviderController extends ChangeNotifier {
  AuthProviderController(this._authService);

  final AuthService _authService;
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _userDocSub;
  StreamSubscription? _authStateSub;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _user != null;
  UserRole? get role => _user?.role;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _authStateSub = _authService.authStateChanges().listen((firebaseUser) {
      _userDocSub?.cancel();
      if (firebaseUser != null) {
        _userDocSub = FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .snapshots()
            .listen((doc) async {
          try {
            if (doc.exists) {
              _user = UserModel.fromFirestore(doc);
              if (_user != null) {
                await NotificationService.updateToken(_user!.uid);
                try {
                  await NotificationService.subscribeToRole(_user!.role.value);
                } catch (_) {}
              }
              _errorMessage = null;
            } else {
              _user = null;
              _errorMessage = "User profile not found in database. Contact admin.";
              await _authService.signOut(); // Force sign out if no profile
            }
          } catch (e) {
            _user = null;
            _errorMessage = "Error loading profile data: $e";
            await _authService.signOut();
          } finally {
            _isLoading = false;
            notifyListeners();
          }
        }, onError: (error) {
          _user = null;
          _errorMessage = "Network or permission error: $error";
          _isLoading = false;
          notifyListeners();
        });
      } else {
        _user = null;
        _isLoading = false;
        notifyListeners();
      }
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
      final credential = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid != null) {
        final newUser = UserModel(
          uid: uid,
          name: name,
          email: email,
          role: role,
          createdAt: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(newUser.toFirestore());

        return true;
      }
      return false;
    } on AuthServiceException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Sign-up failed: $e';
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
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true; // The stream listener will handle _isLoading
    } on AuthServiceException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Sign-in failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
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

  @override
  void dispose() {
    _userDocSub?.cancel();
    _authStateSub?.cancel();
    super.dispose();
  }

  static AuthProviderController of(BuildContext context) {
    return context.read<AuthProviderController>();
  }
}
