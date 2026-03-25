import 'package:hostel_app/features/tshirt/domain/entities/tshirt_order_model.dart';
import 'package:hostel_app/services/mock/mock_service.dart';

class MockTShirtRepository {
  Future<void> placeOrder(TShirtOrderModel order) {
    return MockService.placeTShirtOrder(order);
  }

  Stream<List<TShirtOrderModel>> watchMyOrders(String userId) {
    return MockService.watchMyTShirtOrders(userId);
  }
}
