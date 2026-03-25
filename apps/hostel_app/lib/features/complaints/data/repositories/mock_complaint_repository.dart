import 'package:hostel_app/features/complaints/domain/entities/complaint_model.dart';
import 'package:hostel_app/features/complaints/domain/repositories/complaint_repository.dart';
import 'package:hostel_app/services/mock/mock_service.dart';

class MockComplaintRepository implements ComplaintRepository {
  @override
  Future<void> submitComplaint(ComplaintModel complaint) {
    return MockService.submitComplaint(complaint);
  }

  @override
  Future<void> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
  }) {
    return MockService.updateComplaintStatus(
      complaintId: complaintId,
      status: status,
    );
  }

  @override
  Stream<List<ComplaintModel>> watchComplaints() {
    return MockService.watchComplaints();
  }
}
