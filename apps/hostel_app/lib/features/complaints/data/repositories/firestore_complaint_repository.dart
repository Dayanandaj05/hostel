import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../services/storage/firestore_service.dart';
import '../../domain/entities/complaint_model.dart';
import '../../domain/repositories/complaint_repository.dart';

const _complaintsCollection = 'complaints';

class FirestoreComplaintRepository implements ComplaintRepository {
  FirestoreComplaintRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  @override
  Future<void> submitComplaint(ComplaintModel complaint) async {
    try {
      await _firestoreService
          .collection(_complaintsCollection)
          .add(complaint.toFirestore());
    } on FirebaseException catch (error) {
      throw ComplaintException(
        'Unable to submit complaint right now (${error.code}). Please try again.',
      );
    } catch (_) {
      throw ComplaintException(
        'Unexpected error while submitting complaint. Please try again.',
      );
    }
  }

  @override
  Stream<List<ComplaintModel>> watchComplaints() {
    return _firestoreService
        .collection(_complaintsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ComplaintModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<void> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
  }) async {
    try {
      await _firestoreService.updateDocument(
        path: '$_complaintsCollection/$complaintId',
        data: {
          'status': status.value,
          if (status == ComplaintStatus.resolved)
            'resolvedAt': FieldValue.serverTimestamp(),
        },
      );
    } on FirebaseException catch (error) {
      throw ComplaintException(
        'Unable to update complaint status (${error.code}). Please try again.',
      );
    } catch (_) {
      throw ComplaintException('Unexpected error while updating status.');
    }
  }
}
