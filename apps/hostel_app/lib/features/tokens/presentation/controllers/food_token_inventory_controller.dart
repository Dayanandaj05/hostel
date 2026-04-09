import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/food_token_item_model.dart';
import '../../data/repositories/firestore_food_token_inventory_repository.dart';

class FoodTokenInventoryController extends ChangeNotifier {
  FoodTokenInventoryController(this._repository);
  final FirestoreFoodTokenInventoryRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  List<FoodTokenItemModel> _items = [];
  StreamSubscription? _subscription;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<FoodTokenItemModel> get items => _items;

  void startWatching({bool activeOnly = false}) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();
    _subscription = _repository.watchAllItems(activeOnly: activeOnly).listen(
      (items) {
        _items = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        _errorMessage = 'Unable to load token items.';
        notifyListeners();
      },
    );
  }

  void stopWatching() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<bool> addItem(FoodTokenItemModel item) async {
    try {
      await _repository.addTokenItem(item);
      return true;
    } catch (_) {
      _errorMessage = 'Failed to add item.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItem(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updateTokenItem(id, data);
      return true;
    } catch (_) {
      _errorMessage = 'Failed to update item.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      await _repository.deleteTokenItem(id);
      return true;
    } catch (_) {
      _errorMessage = 'Failed to delete item.';
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }
}
