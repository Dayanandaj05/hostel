import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hostel_app/services/storage/firestore_service.dart';
import 'package:hostel_app/features/leave/domain/entities/leave_request_model.dart';
import 'package:hostel_app/features/leave/domain/repositories/leave_request_repository.dart';

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

  @override
  Stream<List<LeaveRequestModel>> watchMyLeaveRequests(String userId) {
    return _firestoreService
        .collection(_leaveRequestsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LeaveRequestModel.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
              ))
          .toList();
    });
  }

  @override
  Future<void> cancelLeaveRequest(String requestId) async {
    try {
      await _firestoreService
          .collection(_leaveRequestsCollection)
          .doc(requestId)
          .delete();
    } on FirebaseException catch (error) {
      throw LeaveRequestException(
        'Unable to cancel leave request (${error.code}).',
      );
    } catch (_) {
      throw LeaveRequestException(
        'Unexpected error while cancelling leave request.',
      );
    }
  }
}
