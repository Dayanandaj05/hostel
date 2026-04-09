import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfileProvider extends ChangeNotifier {
  StudentProfileProvider();
  String? _currentUid;
  StreamSubscription? _subscription;

  Map<String, dynamic>? profileData;
  bool isLoading = false;
  String? error;

  void startWatching(String uid) {
    if (_currentUid == uid && _subscription != null) return;
    _currentUid = uid;

    if (!isLoading) {
      isLoading = true;
      notifyListeners();
    }

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
      (doc) {
        if (doc.exists) {
          profileData = doc.data() as Map<String, dynamic>;
        } else {
          profileData = null;
          error = 'Profile not found';
        }
        isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        isLoading = false;
        notifyListeners();
      },
    );
  }

  void stopWatching() {
    _subscription?.cancel();
    _subscription = null;
    _currentUid = null;
  }

  String get displayName => profileData?['name'] as String? ?? 'Student';
  String get rollNumber => profileData?['rollNumber'] as String? ?? '--';
  String get email => profileData?['email'] as String? ?? '--';
  String get programme => profileData?['programme'] as String? ?? '--';
  String get yearOfStudy => profileData?['yearOfStudy'] as String? ?? '--';
  String get hostelName => profileData?['hostelName'] as String? ?? '--';
  String get blockName => profileData?['blockName'] as String? ?? '--';
  String get roomNumber => profileData?['roomNumber'] as String? ?? '--';
  String get roomType => profileData?['roomType'] as String? ?? '--';
  String get floor => profileData?['floor'] as String? ?? '--';
  String get joiningDate => profileData?['joiningDate'] as String? ?? '--';
  String get roomId => profileData?['roomId'] as String? ?? '--';
  String get messName => profileData?['messName'] as String? ?? '--';
  // South Indian by default; 'North Indian' if opted in
  String get messType => profileData?['messType'] as String? ?? 'South Indian';
  List<String> get messSupervisors =>
      (profileData?['messSupervisors'] as List?)?.cast<String>() ?? [];
  // true = North Indian opted, false = South Indian (default)
  bool get isNorthIndianMess =>
      (profileData?['messType'] as String?)?.toLowerCase().contains('north') ==
      true;
  int get establishment =>
      (profileData?['establishment'] as num?)?.toInt() ?? 0;
  int get deposit => (profileData?['deposit'] as num?)?.toInt() ?? 0;
  int get balance => (profileData?['balance'] as num?)?.toInt() ?? 0;
  String get contactPhone => profileData?['contactPhone'] as String? ?? '--';
  String get fatherName => profileData?['fatherName'] as String? ?? '--';
  String get address => profileData?['address'] as String? ?? '--';
  String get primaryMobile => profileData?['primaryMobile'] as String? ?? '--';
  String get secondaryMobile =>
      profileData?['secondaryMobile'] as String? ?? '--';
  String get bloodGroup => profileData?['bloodGroup'] as String? ?? '--';

  Future<void> updateProfile({
    String? primaryMobile,
    String? secondaryMobile,
    String? address,
    String? bloodGroup,
  }) async {
    if (profileData == null) return;
    if (_currentUid == null) return;

    final updates = <String, dynamic>{
      if (primaryMobile != null) 'primaryMobile': primaryMobile,
      if (secondaryMobile != null) 'secondaryMobile': secondaryMobile,
      if (address != null) 'address': address,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (updates.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUid)
        .update(updates);
  }

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }
}
