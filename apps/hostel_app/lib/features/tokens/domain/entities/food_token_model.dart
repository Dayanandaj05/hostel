import 'package:cloud_firestore/cloud_firestore.dart';

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
      };

  factory FoodTokenModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FoodTokenModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      itemName: data['itemName'] as String?,
      itemPrice: (data['itemPrice'] as num?)?.toDouble(),
      quantity: data['quantity'] as int?,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 
                 ((data['itemPrice'] as num? ?? 0) * (data['quantity'] as num? ?? 1)).toDouble(),
      mealSlot: data['mealSlot'] as String?,
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate(),
      status: FoodTokenStatusExt.fromString(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
