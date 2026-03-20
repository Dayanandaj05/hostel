import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/food_token_model.dart';
import '../../data/repositories/firestore_food_token_repository.dart';

class FoodTokenController extends ChangeNotifier {
  FoodTokenController(this._repository);

  final FirestoreFoodTokenRepository _repository;

  bool _isSubmitting = false;
  bool _isLoading = false;
  bool _isCancelling = false;
  String? _errorMessage;
  String? _successMessage;
  List<FoodTokenModel> _myTokens = [];
  StreamSubscription? _subscription;

  bool get isSubmitting => _isSubmitting;
  bool get isLoading => _isLoading;
  bool get isCancelling => _isCancelling;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<FoodTokenModel> get myTokens => _myTokens;

  // UI Compatibility Aliases
  bool get isBooking => _isSubmitting;
  bool get isLoadingTokens => _isLoading;

  void startWatchingTokens(String userId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _repository.watchMyTokens(userId).listen(
      (tokens) {
        _myTokens = tokens;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        _errorMessage = 'Unable to load tokens.';
        notifyListeners();
      },
    );
  }

  void stopWatching() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<bool> bookToken({
    required String userId,
    required FoodItem item,
    required int quantity,
    required String mealSlot,
    required DateTime tokenDate,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final token = FoodTokenModel(
        userId: userId,
        itemName: item.name,
        itemPrice: item.price,
        quantity: quantity,
        totalPrice: item.price * quantity,
        mealSlot: mealSlot,
        scheduledDate: tokenDate,
        status: FoodTokenStatus.active,
        foodItemId: item.id,
      );
      await _repository.bookToken(token);
      _successMessage = 'Token booked successfully!';
      return true;
    } catch (e) {
      _errorMessage = 'Failed to book token. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> cancelToken(String tokenId) async {
    _isCancelling = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateTokenStatus(tokenId, FoodTokenStatus.cancelled);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to cancel token.';
      return false;
    } finally {
      _isCancelling = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }
}
