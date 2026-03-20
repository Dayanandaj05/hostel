import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/tshirt_order_model.dart';
import '../../domain/entities/tshirt_models.dart';
import '../../data/repositories/firestore_tshirt_repository.dart';

class TShirtController extends ChangeNotifier {
  TShirtController(this._repository);

  final FirestoreTShirtRepository _repository;

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

  // UI Compatibility Aliases
  bool get isPlacingOrder => _isSubmitting;
  bool get isLoadingOrders => _isLoading;

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
    required TShirtStyle style,
    required String size,
    required int quantity,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    const double pricePerUnit = 450.0; // Default price

    try {
      final order = TShirtOrderModel(
        userId: userId,
        type: style.name,
        size: size,
        quantity: quantity,
        pricePerUnit: pricePerUnit,
        totalPrice: pricePerUnit * quantity,
        status: 'pending',
        styleId: style.id,
      );
      await _repository.placeOrder(order);
      _successMessage = 'T-Shirt order placed successfully!';
      return true;
    } catch (e) {
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
