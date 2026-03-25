import 'package:hostel_app/features/tokens/domain/entities/food_token_model.dart';
import 'package:hostel_app/features/tokens/domain/repositories/food_token_repository.dart';
import 'package:hostel_app/services/mock/mock_service.dart';

class MockFoodTokenRepository implements FoodTokenRepository {
  @override
  Future<void> bookToken(FoodTokenModel token) {
    return MockService.bookToken(token);
  }

  @override
  Future<void> cancelToken(String tokenId) async {}

  @override
  Stream<List<FoodTokenModel>> watchMyTokens(String userId) {
    return MockService.watchMyTokens(userId);
  }
}
