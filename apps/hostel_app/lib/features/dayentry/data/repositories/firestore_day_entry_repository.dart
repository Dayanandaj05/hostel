// lib/features/dayentry/data/repositories/firestore_day_entry_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../services/storage/firestore_service.dart';
import '../../domain/entities/day_entry_model.dart';
import '../../domain/repositories/day_entry_repository.dart';

class FirestoreDayEntryRepository implements DayEntryRepository {
  final FirestoreService _firestoreService;
  static const String _collection = 'day_entry_registrations';

  FirestoreDayEntryRepository(this._firestoreService);

  @override
  Future<void> registerDayEntry(DayEntryModel entry) async {
    await _firestoreService.collection(_collection).add(entry.toFirestore());
  }

  @override
  Stream<List<DayEntryModel>> watchMyRegistrations(String userId) {
    return _firestoreService
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final entries = snapshot.docs
          .map((doc) => DayEntryModel.fromFirestore(doc))
          .toList();
      // Client-side sort by createdAt descending (avoids Firestore composite index)
      entries.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return entries;
    });
  }
}
