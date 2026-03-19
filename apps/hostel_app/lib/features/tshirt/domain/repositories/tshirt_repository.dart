import '../entities/tshirt_models.dart';

abstract class TShirtRepository {
  Future<void> placeOrder(TShirtOrder order);
  Stream<List<TShirtOrder>> watchMyOrders(String userId);
}
