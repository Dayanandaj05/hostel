import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id;
  final String name;
  final double price;
  final String emoji;
  final bool isVeg;

  const FoodItem({
    required this.id,
    required this.name,
    required this.price,
    required this.emoji,
    this.isVeg = true,
  });
}

const kFoodItems = [
  FoodItem(id: 'veg_thali', name: 'Veg Thali', price: 80, emoji: '🍱'),
  FoodItem(id: 'chicken_biryani', name: 'Chicken Biryani', price: 120, emoji: '🍗', isVeg: false),
  FoodItem(id: 'masal_dosa', name: 'Masal Dosa', price: 50, emoji: '🥞'),
  FoodItem(id: 'parotta', name: 'Parotta (2)', price: 40, emoji: '🥐'),
  FoodItem(id: 'fried_rice', name: 'Veg Fried Rice', price: 70, emoji: '🍚'),
  FoodItem(id: 'curd_rice', name: 'Curd Rice', price: 45, emoji: '🥣'),
];

enum FoodTokenStatus { active, used, expired, cancelled }

extension FoodTokenStatusExt on FoodTokenStatus {
  String get value => switch (this) {
        FoodTokenStatus.active => 'active',
        FoodTokenStatus.used => 'used',
        FoodTokenStatus.expired => 'expired',
        FoodTokenStatus.cancelled => 'cancelled',
      };

  static FoodTokenStatus fromString(String? v) => switch (v) {
        'used' => FoodTokenStatus.used,
        'expired' => FoodTokenStatus.expired,
        'cancelled' => FoodTokenStatus.cancelled,
        _ => FoodTokenStatus.active,
      };
}

class FoodTokenModel {
  FoodTokenModel({
    this.id,
    required this.userId,
    this.itemName,
    this.itemPrice,
    this.quantity,
    this.totalPrice,
    this.mealSlot,
    this.scheduledDate,
    required this.status,
    this.createdAt,
    this.foodItemId, // Store original item ID if available
  });

  final String? id;
  final String userId;
  final String? itemName;
  final double? itemPrice;
  final int? quantity;
  final double? totalPrice;
  final String? mealSlot;
  final DateTime? scheduledDate;
  final FoodTokenStatus status;
  final DateTime? createdAt;
  final String? foodItemId;

  // UI Compatibility Aliases
  String get foodItemName => itemName ?? 'Unknown Item';
  double get pricePerItem => itemPrice ?? 0.0;
  DateTime get tokenDate => scheduledDate ?? DateTime.now();
  bool get isActive => status == FoodTokenStatus.active;

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'itemName': itemName,
        'itemPrice': itemPrice,
        'quantity': quantity,
        'totalPrice': totalPrice,
        'mealSlot': mealSlot,
        'scheduledDate':
            scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
        'status': status.value,
        'createdAt': FieldValue.serverTimestamp(),
        'foodItemId': foodItemId,
      };

  factory FoodTokenModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FoodTokenModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      itemName: data['itemName'] as String?,
      itemPrice: (data['itemPrice'] as num?)?.toDouble(),
      quantity: data['quantity'] as int?,
      totalPrice: (data['totalPrice'] as num?)?.toDouble(),
      mealSlot: data['mealSlot'] as String?,
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate(),
      status: FoodTokenStatusExt.fromString(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      foodItemId: data['foodItemId'] as String?,
    );
  }
}
