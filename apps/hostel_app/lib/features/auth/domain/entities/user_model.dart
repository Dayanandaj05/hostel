import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, warden, admin }

extension UserRoleExtension on UserRole {
  String get value => switch (this) {
        UserRole.student => 'student',
        UserRole.warden => 'warden',
        UserRole.admin => 'admin',
      };

  static UserRole? fromString(String? value) {
    return switch (value) {
      'student' => UserRole.student,
      'warden' => UserRole.warden,
      'admin' => UserRole.admin,
      _ => null,
    };
  }
}

class UserModel {
  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.roomId,
    required this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? roomId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      name: data['name'] as String,
      email: data['email'] as String,
      role: UserRoleExtension.fromString(data['role'] as String?) ??
          UserRole.student,
      roomId: data['roomId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.value,
      'roomId': roomId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    String? roomId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      roomId: roomId ?? this.roomId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
