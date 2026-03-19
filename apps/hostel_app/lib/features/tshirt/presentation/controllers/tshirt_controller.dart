import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/tshirt_models.dart';
import '../../domain/repositories/tshirt_repository.dart';

class TShirtController extends ChangeNotifier {
  final TShirtRepository _repository;

  TShirtController(this._repository);

  bool _isPlacingOrder = false;
  bool _isLoadingOrders = false;
  String? _errorMessage;
  String? _successMessage;
  List<TShirtOrder> _myOrders = [];
  StreamSubscription? _orderSubscription;

  bool get isPlacingOrder => _isPlacingOrder;
  bool get isLoadingOrders => _isLoadingOrders;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<TShirtOrder> get myOrders => _myOrders;

  void startWatchingOrders(String userId) {
    _isLoadingOrders = true;
    notifyListeners();

    _orderSubscription?.cancel();
    _orderSubscription = _repository.watchMyOrders(userId).listen(
      (orders) {
        _myOrders = orders;
        _isLoadingOrders = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Failed to load orders: $e';
        _isLoadingOrders = false;
        notifyListeners();
      },
    );
  }

  void stopWatchingOrders() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
  }

  Future<bool> placeOrder({
    required String userId,
    required TShirtStyle style,
    required String size,
    required int quantity,
  }) async {
    _isPlacingOrder = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final order = TShirtOrder(
        userId: userId,
        styleId: style.id,
        styleName: style.name,
        size: size,
        quantity: quantity,
      );

      await _repository.placeOrder(order);
      _successMessage = 'T-Shirt order placed successfully!';
      return true;
    } catch (e) {
      _errorMessage = 'Failed to place order: $e';
      return false;
    } finally {
      _isPlacingOrder = false;
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
    stopWatchingOrders();
    super.dispose();
  }
}
