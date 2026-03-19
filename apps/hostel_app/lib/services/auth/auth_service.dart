import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  User? get currentUser => _firebaseAuth.currentUser;
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException.fromFirebase(error);
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException.fromFirebase(error);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException.fromFirebase(error);
    }
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  Future<String?> getRoleClaim({bool forceRefresh = false}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }

    final idToken = await user.getIdTokenResult(forceRefresh);
    final role = idToken.claims?['role'];
    return role is String ? role : null;
  }
}

class AuthServiceException implements Exception {
  AuthServiceException({required this.code, required this.message});

  final String code;
  final String message;

  factory AuthServiceException.fromFirebase(FirebaseAuthException error) {
    return AuthServiceException(
      code: error.code,
      message: error.message ?? 'Authentication operation failed.',
    );
  }

  @override
  String toString() => 'AuthServiceException(code: $code, message: $message)';
}
