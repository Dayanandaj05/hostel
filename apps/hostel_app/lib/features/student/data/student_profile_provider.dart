import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Watches a single student's Firestore document and exposes profile data
/// reactively via [ChangeNotifier].
class StudentProfileProvider extends ChangeNotifier {
  StudentProfileProvider(this._firestore);

  final FirebaseFirestore _firestore;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  Map<String, dynamic>? _profileData;
  bool _isLoading = false;
  String? _error;

  // ── Public state ──────────────────────────────────────────────────────────

  Map<String, dynamic>? get profileData => _profileData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Convenience getters ───────────────────────────────────────────────────

  String get displayName => _str('name', 'Student');
  String get rollNumber => _str('rollNumber', '--');
  String get programme => _str('programme', '--');
  String get yearOfStudy => _str('yearOfStudy', '--');
  String get email => _str('email', '--');
  String get contactPhone => _str('contactPhone', '--');
  String get fatherName => _str('fatherName', '--');
  String get address => _str('address', '--');
  String get primaryMobile => _str('primaryMobile', '--');
  String get secondaryMobile => _str('secondaryMobile', '--');

  // Hostel
  String get hostelName => _str('hostelName', '--');
  String get blockName => _str('blockName', '--');
  String get roomType => _str('roomType', '--');
  String get floor => _str('floor', '--');
  String get roomNumber => _str('roomNumber', '--');
  String get roomId => _str('roomId', '--');
  String get joiningDate => _str('joiningDate', '--');

  // Mess
  String get messName => _str('messName', '--');
  String get messType => _str('messType', '--');
  List<String> get messSupervisors =>
      (_profileData?['messSupervisors'] as List<dynamic>?)
          ?.cast<String>() ??
      [];
  bool get eggToken => _profileData?['eggToken'] == true;
  bool get nonVegToken => _profileData?['nonVegToken'] == true;

  // Finance
  int get establishment => _int('establishment');
  int get deposit => _int('deposit');
  int get balance => _int('balance');

  // ── Stream control ────────────────────────────────────────────────────────

  void startWatching(String uid) {
    stopWatching();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
      (snapshot) {
        if (uid == 'mock-student-uid') {
          _profileData = {
            'name': 'Guest Student',
            'rollNumber': '25MX301',
            'programme': 'M.C.A.',
            'yearOfStudy': '2nd Year',
            'email': 'guest@psgtech.hostel',
            'contactPhone': '+91 98765 43210',
            'fatherName': 'Demo Parent',
            'address': 'PSG Tech Hostel, Peelamedu, Coimbatore',
            'primaryMobile': '+91 98765 43210',
            'secondaryMobile': '--',
            'hostelName': 'Hostel Block A',
            'blockName': 'A-Block',
            'roomType': 'Double Occupancy',
            'floor': '2nd Floor',
            'roomNumber': 'A-204',
            'joiningDate': '15-06-2024',
            'messName': 'D-Mess (Veg)',
            'messType': 'Vegetarian',
            'messSupervisors': ['Warden John', 'Supervisor Sam'],
            'eggToken': true,
            'nonVegToken': false,
            'establishment': 45000,
            'deposit': 5000,
            'balance': 0,
          };
        } else {
          _profileData = snapshot.data();
        }
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Failed to load profile: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void stopWatching() {
    _subscription?.cancel();
    _subscription = null;
    _profileData = null;
    _isLoading = false;
    _error = null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _str(String key, [String fallback = '--']) =>
      (_profileData?[key] as String?) ?? fallback;

  int _int(String key) => (_profileData?[key] as num?)?.toInt() ?? 0;
}
