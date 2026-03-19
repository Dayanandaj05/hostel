import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../entities/user_model.dart';
import '../../../../services/storage/firestore_service.dart';

const usersCollection = 'users';

class AuthService {
  AuthService({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = FirestoreService(firestore);

  final FirebaseAuth _firebaseAuth;
  final FirestoreService _firestore;

  User? get currentUser => _firebaseAuth.currentUser;
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  Future<UserModel?> getCurrentUserModel() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.getDocument('$usersCollection/${user.uid}');
    if (doc == null) return null;

    return UserModel(
      uid: user.uid,
      name: doc['name'] as String? ?? user.displayName ?? 'User',
      email: doc['email'] as String? ?? user.email ?? '',
      role: UserRoleExtension.fromString(doc['role'] as String?) ??
          UserRole.student,
      roomId: doc['roomId'] as String?,
      createdAt: doc['createdAt'] != null
          ? (doc['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Stream<UserModel?> watchCurrentUserModel() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore.watchDocument('$usersCollection/${user.uid}').map((doc) {
      if (doc == null) return null;

      return UserModel(
        uid: user.uid,
        name: doc['name'] as String? ?? user.displayName ?? 'User',
        email: doc['email'] as String? ?? user.email ?? '',
        role: UserRoleExtension.fromString(doc['role'] as String?) ??
            UserRole.student,
        roomId: doc['roomId'] as String?,
        createdAt: doc['createdAt'] != null
            ? (doc['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    });
  }

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await createUserDocument(user.uid, name, email, role);
      }

      return credential;
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException.fromFirebase(error);
    }
  }

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

  Future<void> createUserDocument(
    String uid,
    String name,
    String email,
    UserRole role,
  ) async {
    final userModel = UserModel(
      uid: uid,
      name: name,
      email: email,
      role: role,
      createdAt: DateTime.now(),
    );

    await _firestore.setDocument(
      path: '$usersCollection/$uid',
      data: userModel.toFirestore(),
      merge: false,
    );
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    await _firestore.updateDocument(
      path: '$usersCollection/$uid',
      data: {'role': role.value},
    );
  }

  Future<void> allocateRoom(String uid, String roomId) async {
    await _firestore.updateDocument(
      path: '$usersCollection/$uid',
      data: {'roomId': roomId},
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException.fromFirebase(error);
    }
  }

  Future<void> signOut() => _firebaseAuth.signOut();
}

class AuthServiceException implements Exception {
  AuthServiceException({required this.code, required this.message});

  final String code;
  final String message;

  factory AuthServiceException.fromFirebase(FirebaseAuthException error) {
    final message = switch (error.code) {
      'user-not-found' => 'No user found with that email.',
      'wrong-password' => 'Incorrect password.',
      'email-already-in-use' => 'An account with that email already exists.',
      'weak-password' => 'Password is too weak. Use at least 6 characters.',
      'invalid-email' => 'The email address is invalid.',
      _ => error.message ?? 'Authentication operation failed.',
    };

    return AuthServiceException(
      code: error.code,
      message: message,
    );
  }

  @override
  String toString() => 'AuthServiceException(code: $code, message: $message)';
}
