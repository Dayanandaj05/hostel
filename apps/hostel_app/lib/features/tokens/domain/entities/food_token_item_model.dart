import 'package:cloud_firestore/cloud_firestore.dart';

class FoodTokenItemModel {
  final String id;
  final String name;
  final double price;
  final int limitPerPerson;
  final int totalQuantity;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FoodTokenItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.limitPerPerson,
    required this.totalQuantity,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory FoodTokenItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FoodTokenItemModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Unknown',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      limitPerPerson: data['limitPerPerson'] as int? ?? 1,
      totalQuantity: data['totalQuantity'] as int? ?? 100,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'limitPerPerson': limitPerPerson,
      'totalQuantity': totalQuantity,
      'isActive': isActive,
    };
  }

  FoodTokenItemModel copyWith({
    String? name,
    double? price,
    int? limitPerPerson,
    int? totalQuantity,
    bool? isActive,
  }) {
    return FoodTokenItemModel(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      limitPerPerson: limitPerPerson ?? this.limitPerPerson,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
