import '../../../../services/storage/firestore_service.dart';
import '../../domain/entities/food_token_model.dart';

class FirestoreFoodTokenRepository {
  FirestoreFoodTokenRepository(this._firestoreService);
  final FirestoreService _firestoreService;
  static const _collection = 'food_tokens';

  Future<void> bookToken(FoodTokenModel token) async {
    await _firestoreService.collection(_collection).add(token.toFirestore());
  }

  Stream<List<FoodTokenModel>> watchMyTokens(String userId) {
    return _firestoreService
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) => FoodTokenModel.fromFirestore(doc)).toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }
}
