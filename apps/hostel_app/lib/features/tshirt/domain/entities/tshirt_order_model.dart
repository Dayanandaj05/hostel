import 'package:cloud_firestore/cloud_firestore.dart';

class TShirtOrderModel {
  TShirtOrderModel({
    this.id,
    required this.userId,
    required this.type,
    required this.size,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.status,
    this.createdAt,
    this.styleId,
  });

  final String? id;
  final String userId;
  final String type; // This is styleName in existing UI
  final String size;
  final int quantity;
  final double pricePerUnit;
  final double totalPrice;
  final String status;
  final DateTime? createdAt;
  final String? styleId;

  // UI Compatibility Aliases
  String get styleName => type;

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'type': type,
        'size': size,
        'quantity': quantity,
        'pricePerUnit': pricePerUnit,
        'totalPrice': totalPrice,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'styleId': styleId,
      };

  factory TShirtOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TShirtOrderModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      size: data['size'] as String? ?? '',
      quantity: data['quantity'] as int? ?? 1,
      pricePerUnit: (data['pricePerUnit'] as num?)?.toDouble() ?? 0,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0,
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      styleId: data['styleId'] as String?,
    );
  }
}
