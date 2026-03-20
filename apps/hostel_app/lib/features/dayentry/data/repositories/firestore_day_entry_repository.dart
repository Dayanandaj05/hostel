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
    await _firestoreService.addDocument(_collection, entry.toFirestore());
  }

  @override
  Stream<List<DayEntryModel>> watchMyRegistrations(String userId) {
    return _firestoreService.watchCollection(
      _collection,
      queryBuilder: (query) => query
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true),
    ).map((snapshot) {
      return snapshot.docs.map((doc) => DayEntryModel.fromFirestore(doc)).toList();
    });
  }
}
