import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.price,
    required this.emoji,
    required this.isVeg,
  });

  final String id;
  final String name;
  final int price;
  final String emoji;
  final bool isVeg;
}

const kFoodItems = [
  FoodItem(id: 'gobi_chilli', name: 'Gobi Chilli', price: 40, emoji: '🥦', isVeg: true),
  FoodItem(id: 'chicken_gravy', name: 'Chicken Gravy', price: 80, emoji: '🍗', isVeg: false),
  FoodItem(id: 'mushroom_manchurian', name: 'Mushroom Manchurian', price: 60, emoji: '🍄', isVeg: true),
  FoodItem(id: 'omelette', name: 'Omelette', price: 10, emoji: '🍳', isVeg: false),
  FoodItem(id: 'boiled_egg', name: 'Boiled Egg', price: 10, emoji: '🥚', isVeg: false),
  FoodItem(id: 'full_boil_egg', name: 'Full Boil Egg', price: 10, emoji: '🥚', isVeg: false),
  FoodItem(id: 'egg_gravy', name: 'Egg Gravy', price: 25, emoji: '🥘', isVeg: false),
];

class FoodTokenModel {
  FoodTokenModel({
    this.id,
    required this.userId,
    required this.foodItemId,
    required this.foodItemName,
    required this.pricePerItem,
    required this.quantity,
    required this.totalPrice,
    required this.tokenDate,
    required this.mealSlot,
    required this.isActive,
    this.createdAt,
  });

  final String? id;
  final String userId;
  final String foodItemId;
  final String foodItemName;
  final int pricePerItem;
  final int quantity;
  final int totalPrice;
  final DateTime tokenDate;
  final String mealSlot;
  final bool isActive;
  final DateTime? createdAt;

  factory FoodTokenModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FoodTokenModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      foodItemId: data['foodItemId'] ?? '',
      foodItemName: data['foodItemName'] ?? '',
      pricePerItem: data['pricePerItem'] ?? 0,
      quantity: data['quantity'] ?? 1,
      totalPrice: data['totalPrice'] ?? 0,
      tokenDate: (data['tokenDate'] as Timestamp).toDate(),
      mealSlot: data['mealSlot'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'foodItemId': foodItemId,
      'foodItemName': foodItemName,
      'pricePerItem': pricePerItem,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'tokenDate': Timestamp.fromDate(tokenDate),
      'mealSlot': mealSlot,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
