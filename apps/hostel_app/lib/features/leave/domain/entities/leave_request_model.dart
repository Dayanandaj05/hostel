import 'package:cloud_firestore/cloud_firestore.dart';

enum LeaveRequestStatus { pending, approved, rejected }

extension LeaveRequestStatusExtension on LeaveRequestStatus {
  String get value => switch (this) {
        LeaveRequestStatus.pending => 'pending',
        LeaveRequestStatus.approved => 'approved',
        LeaveRequestStatus.rejected => 'rejected',
      };
}

class LeaveRequestModel {
  LeaveRequestModel({
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.createdAt,
  });

  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveRequestStatus status;
  final DateTime? createdAt;

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'reason': reason,
      'status': status.value,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
