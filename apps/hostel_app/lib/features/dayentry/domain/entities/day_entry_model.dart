import 'package:cloud_firestore/cloud_firestore.dart';

class DayEntryVisitor {
  final String name;
  final String relation; // 'Father', 'Mother', 'Guardian', 'Sibling', 'Other'
  final String mobile;

  DayEntryVisitor({
    required this.name,
    required this.relation,
    required this.mobile,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relation': relation,
      'mobile': mobile,
    };
  }

  factory DayEntryVisitor.fromMap(Map<String, dynamic> map) {
    return DayEntryVisitor(
      name: map['name'] ?? '',
      relation: map['relation'] ?? '',
      mobile: map['mobile'] ?? '',
    );
  }
}

class DayEntryModel {
  final String? id;
  final String userId;
  final String passNumber;
  final String studentName;
  final String rollNumber;
  final String roomNumber;
  final String programme;
  final DateTime visitDate;
  final String timeSlot;
  final List<DayEntryVisitor> visitors;
  final String status;
  final DateTime? createdAt;

  DayEntryModel({
    this.id,
    required this.userId,
    required this.passNumber,
    required this.studentName,
    required this.rollNumber,
    required this.roomNumber,
    required this.programme,
    required this.visitDate,
    required this.timeSlot,
    required this.visitors,
    required this.status,
    this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'passNumber': passNumber,
      'studentName': studentName,
      'rollNumber': rollNumber,
      'roomNumber': roomNumber,
      'programme': programme,
      'visitDate': Timestamp.fromDate(visitDate),
      'timeSlot': timeSlot,
      'visitors': visitors.map((v) => v.toMap()).toList(),
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory DayEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DayEntryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      passNumber: data['passNumber'] ?? '',
      studentName: data['studentName'] ?? '',
      rollNumber: data['rollNumber'] ?? '',
      roomNumber: data['roomNumber'] ?? '',
      programme: data['programme'] ?? '',
      visitDate: (data['visitDate'] as Timestamp).toDate(),
      timeSlot: data['timeSlot'] ?? '',
      visitors: (data['visitors'] as List? ?? [])
          .map((v) => DayEntryVisitor.fromMap(v as Map<String, dynamic>))
          .toList(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
