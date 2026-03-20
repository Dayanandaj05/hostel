import '../../../../services/storage/firestore_service.dart';
import '../../domain/entities/tshirt_order_model.dart';

class FirestoreTShirtRepository {
  FirestoreTShirtRepository(this._firestoreService);

  final FirestoreService _firestoreService;
  static const _collection = 'tshirt_orders';

  Future<void> placeOrder(TShirtOrderModel order) async {
    await _firestoreService.collection(_collection).add(order.toFirestore());
  }

  Stream<List<TShirtOrderModel>> watchMyOrders(String userId) {
    return _firestoreService
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => TShirtOrderModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }
}
