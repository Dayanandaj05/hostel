import '../entities/food_token_model.dart';

abstract class FoodTokenRepository {
  Future<void> bookToken(FoodTokenModel token);
  Stream<List<FoodTokenModel>> watchMyTokens(String userId);
  Future<void> cancelToken(String tokenId);
}
