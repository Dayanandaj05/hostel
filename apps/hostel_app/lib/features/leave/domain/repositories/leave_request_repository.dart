import '../entities/leave_request_model.dart';

class LeaveRequestException implements Exception {
  LeaveRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class LeaveRequestRepository {
  Future<void> submitLeaveRequest(LeaveRequestModel leaveRequest);
}
