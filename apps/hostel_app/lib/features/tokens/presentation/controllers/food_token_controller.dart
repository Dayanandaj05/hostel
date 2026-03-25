import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/food_token_model.dart';
import '../../domain/repositories/food_token_repository.dart';

class FoodTokenController extends ChangeNotifier {
  FoodTokenController(this._repository);
  final FoodTokenRepository _repository;

  bool _isSubmitting = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  List<FoodTokenModel> _myTokens = [];
  StreamSubscription? _subscription;
  String? _currentUserId;

  bool get isSubmitting => _isSubmitting;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<FoodTokenModel> get myTokens => _myTokens;

  void startWatchingTokens(String userId) {
    if (_currentUserId == userId && _subscription != null) return;
    _currentUserId = userId;

    _subscription?.cancel();
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

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
    required String itemName,
    required double itemPrice,
    required int quantity,
    required String mealSlot,
    required DateTime scheduledDate,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      final token = FoodTokenModel(
        userId: userId,
        itemName: itemName,
        itemPrice: itemPrice,
        quantity: quantity,
        totalPrice: itemPrice * quantity,
        mealSlot: mealSlot,
        scheduledDate: scheduledDate,
        status: FoodTokenStatus.active,
      );
      await _repository.bookToken(token);
      _successMessage = 'Token booked successfully!';
      return true;
    } catch (_) {
      _errorMessage = 'Failed to book token. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
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
