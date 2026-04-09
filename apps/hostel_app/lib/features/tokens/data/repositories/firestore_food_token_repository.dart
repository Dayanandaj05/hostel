import '../../../../services/storage/firestore_service.dart';
import '../../domain/entities/food_token_model.dart';
import '../../domain/repositories/food_token_repository.dart';

class FirestoreFoodTokenRepository implements FoodTokenRepository {
  FirestoreFoodTokenRepository(this._firestoreService);
  final FirestoreService _firestoreService;
  static const _collection = 'food_tokens';

  @override
  Future<void> bookToken(FoodTokenModel token) async {
    await _firestoreService.collection(_collection).add(token.toFirestore());
  }

  @override
  Future<void> cancelToken(String tokenId) async {
    await _firestoreService.collection(_collection).doc(tokenId).update({'status': 'cancelled'});
  }

  @override
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
