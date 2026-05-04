import 'package:cloud_firestore/cloud_firestore.dart';

class FoodTokenItemModel {
  final String id;
  final String name;
  final double price;
  final int limitPerPerson;
  final int totalQuantity;
  final String mealSlot;
  final String audience;
  final bool isVeg;
  final String? emoji;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FoodTokenItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.limitPerPerson,
    required this.totalQuantity,
    this.mealSlot = 'Lunch',
    this.audience = 'Both',
    this.isVeg = true,
    this.emoji,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory FoodTokenItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FoodTokenItemModel(
      id: doc.id,
      name: (data['name'] as String?) ??
          (data['itemName'] as String?) ??
          'Unknown',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      limitPerPerson: (data['limitPerPerson'] as num?)?.toInt() ?? 1,
      totalQuantity: (data['totalQuantity'] as num?)?.toInt() ?? 100,
      mealSlot: data['mealSlot'] as String? ?? 'Lunch',
      audience: (data['audience'] as String?) ??
          (data['messCategory'] as String?) ??
          'Both',
      isVeg: data['isVeg'] as bool? ?? true,
      emoji: data['emoji'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'itemName': name,
      'price': price,
      'limitPerPerson': limitPerPerson,
      'totalQuantity': totalQuantity,
      'mealSlot': mealSlot,
      'audience': audience,
      'messCategory': audience,
      'isVeg': isVeg,
      'emoji': emoji,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  FoodTokenItemModel copyWith({
    String? name,
    double? price,
    int? limitPerPerson,
    int? totalQuantity,
    String? mealSlot,
    String? audience,
    bool? isVeg,
    String? emoji,
    bool? isActive,
  }) {
    return FoodTokenItemModel(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      limitPerPerson: limitPerPerson ?? this.limitPerPerson,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      mealSlot: mealSlot ?? this.mealSlot,
      audience: audience ?? this.audience,
      isVeg: isVeg ?? this.isVeg,
      emoji: emoji ?? this.emoji,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
