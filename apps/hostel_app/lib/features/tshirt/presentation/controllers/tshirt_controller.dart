import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/tshirt_order_model.dart';
import '../../data/repositories/mock_tshirt_repository.dart';

class TShirtController extends ChangeNotifier {
  TShirtController(this._repository);
  final MockTShirtRepository _repository;

  bool _isSubmitting = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  List<TShirtOrderModel> _myOrders = [];
  StreamSubscription? _subscription;

  bool get isSubmitting => _isSubmitting;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<TShirtOrderModel> get myOrders => _myOrders;

  void startWatchingOrders(String userId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();
    _subscription = _repository.watchMyOrders(userId).listen(
      (orders) {
        _myOrders = orders;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        _errorMessage = 'Unable to load orders.';
        notifyListeners();
      },
    );
  }

  void stopWatching() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<bool> placeOrder({
    required String userId,
    required String type,
    required String size,
    required int quantity,
    required double pricePerUnit,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      final order = TShirtOrderModel(
        userId: userId,
        type: type,
        size: size,
        quantity: quantity,
        pricePerUnit: pricePerUnit,
        totalPrice: pricePerUnit * quantity,
        status: 'pending',
      );
      await _repository.placeOrder(order);
      _successMessage = 'T-Shirt order placed successfully!';
      return true;
    } catch (_) {
      _errorMessage = 'Failed to place order. Please try again.';
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
