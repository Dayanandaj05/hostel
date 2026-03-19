import 'package:cloud_firestore/cloud_firestore.dart';

enum ComplaintStatus { pending, inProgress, resolved }

extension ComplaintStatusExtension on ComplaintStatus {
  String get value => switch (this) {
        ComplaintStatus.pending => 'pending',
        ComplaintStatus.inProgress => 'in_progress',
        ComplaintStatus.resolved => 'resolved',
      };

  static ComplaintStatus fromString(String? value) {
    return switch (value) {
      'in_progress' => ComplaintStatus.inProgress,
      'resolved' => ComplaintStatus.resolved,
      _ => ComplaintStatus.pending,
    };
  }

  String get label => switch (this) {
        ComplaintStatus.pending => 'Pending',
        ComplaintStatus.inProgress => 'In Progress',
        ComplaintStatus.resolved => 'Resolved',
      };
}

class ComplaintModel {
  ComplaintModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final ComplaintStatus status;
  final DateTime? createdAt;

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'status': status.value,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ComplaintModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final createdAtRaw = data['createdAt'];

    return ComplaintModel(
      id: snapshot.id,
      userId: (data['userId'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      status: ComplaintStatusExtension.fromString(data['status'] as String?),
      createdAt: createdAtRaw is Timestamp ? createdAtRaw.toDate() : null,
    );
  }
}
