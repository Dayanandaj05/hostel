import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/food_token_model.dart';
import '../../domain/repositories/food_token_repository.dart';

class FoodTokenController extends ChangeNotifier {
  FoodTokenController(this._repository);

  final FoodTokenRepository _repository;

  bool _isBooking = false;
  bool _isLoadingTokens = false;
  bool _isCancelling = false;
  String? _errorMessage;
  String? _successMessage;
  List<FoodTokenModel> _myTokens = [];
  StreamSubscription? _tokenSubscription;

  bool get isBooking => _isBooking;
  bool get isLoadingTokens => _isLoadingTokens;
  bool get isCancelling => _isCancelling;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<FoodTokenModel> get myTokens => _myTokens;

  void startWatchingTokens(String userId) {
    stopWatchingTokens();
    _isLoadingTokens = true;
    notifyListeners();

    _tokenSubscription = _repository.watchMyTokens(userId).listen(
      (tokens) {
        _myTokens = tokens;
        _isLoadingTokens = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Failed to load tokens: $e';
        _isLoadingTokens = false;
        notifyListeners();
      },
    );
  }

  void stopWatchingTokens() {
    _tokenSubscription?.cancel();
    _tokenSubscription = null;
  }

  Future<bool> bookToken({
    required String userId,
    required FoodItem item,
    required int quantity,
    required DateTime tokenDate,
    required String mealSlot,
  }) async {
    _isBooking = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final token = FoodTokenModel(
      userId: userId,
      foodItemId: item.id,
      foodItemName: item.name,
      pricePerItem: item.price,
      quantity: quantity,
      totalPrice: item.price * quantity,
      tokenDate: tokenDate,
      mealSlot: mealSlot,
      isActive: true,
    );

    try {
      await _repository.bookToken(token);
      _successMessage = 'Token booked successfully!';
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isBooking = false;
      notifyListeners();
    }
  }

  Future<bool> cancelToken(String tokenId) async {
    _isCancelling = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repository.cancelToken(tokenId);
      _successMessage = 'Token cancelled successfully!';
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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
    stopWatchingTokens();
    super.dispose();
  }
}
