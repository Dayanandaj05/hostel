import 'package:cloud_firestore/cloud_firestore.dart';

class TShirtStyle {
  final String id;
  final String name;
  final String emoji;

  const TShirtStyle({
    required this.id,
    required this.name,
    required this.emoji,
  });
}

const kTShirtStyles = [
  TShirtStyle(id: 'round_neck_full', name: 'Round Neck Full Hand', emoji: '👕'),
  TShirtStyle(id: 'collar_half', name: 'Collar Half Hand', emoji: '👔'),
];

class TShirtSize {
  final String label;
  final String chest;
  final String length;

  const TShirtSize({
    required this.label,
    required this.chest,
    required this.length,
  });
}

const kTShirtSizes = [
  TShirtSize(label: 'XS', chest: '32"', length: '26"'),
  TShirtSize(label: 'S', chest: '34"', length: '27"'),
  TShirtSize(label: 'M', chest: '36"', length: '28"'),
  TShirtSize(label: 'L', chest: '38"', length: '29"'),
  TShirtSize(label: 'XL', chest: '40"', length: '30"'),
  TShirtSize(label: 'XXL', chest: '42"', length: '31"'),
  TShirtSize(label: 'XXXL', chest: '44"', length: '32"'),
];

class TShirtOrder {
  final String? id;
  final String userId;
  final String styleId;
  final String styleName;
  final String size;
  final int quantity;
  final String status; // 'pending', 'confirmed', 'delivered'
  final DateTime? createdAt;

  TShirtOrder({
    this.id,
    required this.userId,
    required this.styleId,
    required this.styleName,
    required this.size,
    required this.quantity,
    this.status = 'pending',
    this.createdAt,
  });

  factory TShirtOrder.fromFirestore(Map<String, dynamic> json, String id) {
    return TShirtOrder(
      id: id,
      userId: json['userId'] as String,
      styleId: json['styleId'] as String,
      styleName: json['styleName'] as String,
      size: json['size'] as String,
      quantity: json['quantity'] as int,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'styleId': styleId,
      'styleName': styleName,
      'size': size,
      'quantity': quantity,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
