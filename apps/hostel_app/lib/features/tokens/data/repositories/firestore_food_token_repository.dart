import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../services/storage/firestore_service.dart';
import '../../domain/entities/food_token_model.dart';
import '../../domain/repositories/food_token_repository.dart';

const _foodTokensCollection = 'food_tokens';

class FirestoreFoodTokenRepository implements FoodTokenRepository {
  FirestoreFoodTokenRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  @override
  Future<void> bookToken(FoodTokenModel token) async {
    try {
      await _firestoreService
          .collection(_foodTokensCollection)
          .add(token.toFirestore());
    } catch (e) {
      throw Exception('Failed to book token: $e');
    }
  }

  @override
  Stream<List<FoodTokenModel>> watchMyTokens(String userId) {
    return _firestoreService
        .collection(_foodTokensCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final tokens = snapshot.docs
          .map((doc) => FoodTokenModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
      
      // Client-side sorting by createdAt descending
      tokens.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.now();
        final bTime = b.createdAt ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      
      return tokens;
    });
  }

  @override
  Future<void> cancelToken(String tokenId) async {
    try {
      await _firestoreService
          .collection(_foodTokensCollection)
          .doc(tokenId)
          .delete();
    } catch (e) {
      throw Exception('Failed to cancel token: $e');
    }
  }
}
