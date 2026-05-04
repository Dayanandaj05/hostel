import '../../../../services/storage/firestore_service.dart';
import '../../domain/entities/food_token_item_model.dart';

class FirestoreFoodTokenInventoryRepository {
  FirestoreFoodTokenInventoryRepository(this._firestoreService);
  final FirestoreService _firestoreService;
  static const _collection = 'food_token_items';

  Future<void> addTokenItem(FoodTokenItemModel item) async {
    await _firestoreService.collection(_collection).add(item.toFirestore());
  }

  Future<void> updateTokenItem(String id, Map<String, dynamic> data) async {
    await _firestoreService.updateDocument(
        path: '$_collection/$id', data: data);
  }

  Future<void> deleteTokenItem(String id) async {
    await _firestoreService.deleteDocument('$_collection/$id');
  }

  Stream<List<FoodTokenItemModel>> watchAllItems({bool activeOnly = false}) {
    return _firestoreService.collection(_collection).snapshots().map((snap) {
      var items = snap.docs
          .map((doc) => FoodTokenItemModel.fromFirestore(doc))
          .toList();

      if (activeOnly) {
        items = items.where((item) => item.isActive).toList();
      }

      items.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return items;
    });
  }
}
