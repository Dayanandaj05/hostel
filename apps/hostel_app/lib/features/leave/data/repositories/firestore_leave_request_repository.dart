import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../services/storage/firestore_service.dart';
import '../../domain/entities/leave_request_model.dart';
import '../../domain/repositories/leave_request_repository.dart';

const _leaveRequestsCollection = 'leave_requests';

class FirestoreLeaveRequestRepository implements LeaveRequestRepository {
  FirestoreLeaveRequestRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  @override
  Future<void> submitLeaveRequest(LeaveRequestModel leaveRequest) async {
    try {
      await _firestoreService
          .collection(_leaveRequestsCollection)
          .add(leaveRequest.toFirestore());
    } on FirebaseException catch (error) {
      throw LeaveRequestException(
        'Unable to submit leave request right now (${error.code}). Please try again.',
      );
    } catch (_) {
      throw LeaveRequestException(
        'Unexpected error while submitting leave request. Please try again.',
      );
    }
  }
}
