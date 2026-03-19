import '../entities/complaint_model.dart';

class ComplaintException implements Exception {
  ComplaintException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class ComplaintRepository {
  Future<void> submitComplaint(ComplaintModel complaint);

  Stream<List<ComplaintModel>> watchComplaints();

  Future<void> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
  });
}
