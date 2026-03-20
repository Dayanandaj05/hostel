import 'package:cloud_firestore/cloud_firestore.dart';

enum LeaveRequestStatus { pending, approved, rejected }

extension LeaveRequestStatusExtension on LeaveRequestStatus {
  String get value => switch (this) {
        LeaveRequestStatus.pending => 'pending',
        LeaveRequestStatus.approved => 'approved',
        LeaveRequestStatus.rejected => 'rejected',
      };

  static LeaveRequestStatus fromString(String? value) => switch (value) {
        'approved' => LeaveRequestStatus.approved,
        'rejected' => LeaveRequestStatus.rejected,
        _ => LeaveRequestStatus.pending,
      };
}
class LeaveRequestModel {
  LeaveRequestModel({
    this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.leaveType,
    this.approvalManager,
    this.createdAt,
  });

  final String? id;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveRequestStatus status;
  final String? leaveType;
  final String? approvalManager;
  final DateTime? createdAt;

  factory LeaveRequestModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return LeaveRequestModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      startDate: data['startDate'] != null 
          ? (data['startDate'] as Timestamp).toDate() 
          : DateTime.now(),
      endDate: data['endDate'] != null 
          ? (data['endDate'] as Timestamp).toDate() 
          : DateTime.now().add(const Duration(days: 1)),
      reason: data['reason'] ?? '',
      leaveType: data['leaveType'] as String?,
      approvalManager: data['approvalManager'] as String?,
      status: LeaveRequestStatusExtension.fromString(data['status'] as String?),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'reason': reason,
      'status': status.value,
      'leaveType': leaveType,
      'approvalManager': approvalManager,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
