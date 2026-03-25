import '../entities/user_model.dart';
import '../../../../services/mock/mock_service.dart';

const usersCollection = 'users';

class AuthService {
  AuthService();

  UserModel? get currentUser => MockService.currentUser;
  String? get currentUserId => MockService.currentUid;

  Stream<UserModel?> authStateChanges() => MockService.watchCurrentUserModel();

  Future<UserModel?> getCurrentUserModel() async {
    return MockService.getCurrentUserModel();
  }

  Stream<UserModel?> watchCurrentUserModel() {
    return MockService.watchCurrentUserModel();
  }

  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      final user = await MockService.signUp(
        email: email.trim(),
        password: password,
        name: name,
        role: role,
      );
      if (user == null) {
        throw AuthServiceException(
            code: 'signup-failed', message: 'Sign-up failed.');
      }
      return user;
    } on AuthServiceException {
      rethrow;
    } catch (error) {
      throw AuthServiceException(
        code: 'signup-failed',
        message: error.toString(),
      );
    }
  }

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await MockService.signIn(
        email: email.trim(),
        password: password,
      );
      if (user == null) {
        throw AuthServiceException(
          code: 'wrong-password',
          message: 'Incorrect email or password.',
        );
      }
      return user;
    } on AuthServiceException {
      rethrow;
    } catch (error) {
      throw AuthServiceException(
          code: 'signin-failed', message: error.toString());
    }
  }

  Future<void> createUserDocument(
    String uid,
    String name,
    String email,
    UserRole role,
  ) async {
    await MockService.signUp(
        email: email, password: '123456', name: name, role: role);
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    // Mock mode: user role updates can be added here if needed.
  }

  Future<void> allocateRoom(String uid, String roomId) async {
    // Mock mode: room allocation can be added here if needed.
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await MockService.sendPasswordResetEmail(email.trim());
    } catch (error) {
      throw AuthServiceException(
          code: 'reset-failed', message: error.toString());
    }
  }

  Future<void> signOut() => MockService.signOut();
}

class AuthServiceException implements Exception {
  AuthServiceException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'AuthServiceException(code: $code, message: $message)';
}
