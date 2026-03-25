import 'package:hostel_app/features/leave/domain/entities/leave_request_model.dart';
import 'package:hostel_app/features/leave/domain/repositories/leave_request_repository.dart';
import 'package:hostel_app/services/mock/mock_service.dart';

class MockLeaveRequestRepository implements LeaveRequestRepository {
  @override
  Future<void> cancelLeaveRequest(String requestId) {
    return MockService.cancelLeaveRequest(requestId);
  }

  @override
  Future<void> submitLeaveRequest(LeaveRequestModel leaveRequest) {
    return MockService.submitLeaveRequest(leaveRequest);
  }

  @override
  Stream<List<LeaveRequestModel>> watchMyLeaveRequests(String userId) {
    return MockService.watchMyLeaveRequests(userId);
  }
}
