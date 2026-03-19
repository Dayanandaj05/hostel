import 'package:hostel_app/features/tshirt/domain/entities/tshirt_models.dart';
import 'package:hostel_app/features/tshirt/domain/repositories/tshirt_repository.dart';
import 'package:hostel_app/services/storage/firestore_service.dart';

class FirestoreTShirtRepository implements TShirtRepository {
  final FirestoreService _firestoreService;
  final String _collection = 'tshirt_orders';

  FirestoreTShirtRepository(this._firestoreService);

  @override
  Future<void> placeOrder(TShirtOrder order) async {
    final docRef = _firestoreService.collection(_collection).doc();
    await _firestoreService.setDocument(
      path: '$_collection/${docRef.id}',
      data: order.toFirestore(),
      merge: false,
    );
  }

  @override
  Stream<List<TShirtOrder>> watchMyOrders(String userId) {
    return _firestoreService
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) {
        return TShirtOrder.fromFirestore(doc.data(), doc.id);
      }).toList();

      // Client-side sort by createdAt desc
      orders.sort((a, b) {
        if (a.createdAt == null) return -1;
        if (b.createdAt == null) return 1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return orders;
    });
  }
}
