import 'dart:async';

import 'package:hostel_app/features/auth/domain/entities/user_model.dart';
import 'package:hostel_app/features/complaints/domain/entities/complaint_model.dart';
import 'package:hostel_app/features/dayentry/domain/entities/day_entry_model.dart';
import 'package:hostel_app/features/leave/domain/entities/leave_request_model.dart';
import 'package:hostel_app/features/tokens/domain/entities/food_token_model.dart';
import 'package:hostel_app/features/tshirt/domain/entities/tshirt_order_model.dart';

import 'mock_data.dart';

class MockService {
  MockService._();

  static const Duration mockDelay = Duration(milliseconds: 500);
  static String? _currentUid;

  static final StreamController<void> _changes =
      StreamController<void>.broadcast();

  static Stream<void> get changes => _changes.stream;

  static Future<void> _delay() => Future.delayed(mockDelay);

  static void _notify() => _changes.add(null);

  static String? get currentUid => _currentUid;

  static UserModel? get currentUser {
    if (_currentUid == null) return null;
    for (final user in MockData.users) {
      if (user.uid == _currentUid) return user;
    }
    return null;
  }

  static Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    await _delay();
    final cleanEmail = email.trim().toLowerCase();
    final expected = MockData.passwords[cleanEmail];
    if (expected == null || expected != password) {
      return null;
    }
    final user = MockData.users
        .where((u) => u.email.toLowerCase() == cleanEmail)
        .toList();
    _currentUid = user.isNotEmpty ? user.first.uid : null;
    _notify();
    return user.isNotEmpty ? user.first : null;
  }

  static Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    await _delay();
    final cleanEmail = email.trim().toLowerCase();
    if (MockData.passwords.containsKey(cleanEmail)) {
      throw StateError('Account already exists for this email.');
    }
    final uid = 'user-${DateTime.now().millisecondsSinceEpoch}';
    final user = UserModel(
      uid: uid,
      name: name,
      email: cleanEmail,
      role: role,
      roomId: role == UserRole.student ? 'A-101' : null,
      createdAt: DateTime.now(),
    );
    MockData.users.add(user);
    MockData.passwords[cleanEmail] = password;
    MockData.studentProfiles[uid] = {
      'name': name,
      'rollNumber': 'NEW001',
      'email': cleanEmail,
      'programme': 'MCA',
      'yearOfStudy': '1',
      'hostelName': 'PSG Men Hostel',
      'blockName': 'A Block',
      'roomNumber': '101',
      'roomType': 'Double',
      'floor': '1',
      'joiningDate': DateTime.now().toIso8601String().split('T').first,
      'roomId': 'A-101',
      'messName': 'Main Mess',
      'messType': 'South Indian',
      'messSupervisors': ['Mr. Rajan'],
      'balance': 0,
      'contactPhone': '--',
      'fatherName': '--',
      'address': '--',
      'primaryMobile': '--',
      'secondaryMobile': '--',
      'bloodGroup': '--',
    };
    _currentUid = uid;
    _notify();
    return user;
  }

  static Future<void> signOut() async {
    await _delay();
    _currentUid = null;
    _notify();
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    await _delay();
    if (!MockData.passwords.containsKey(email.trim().toLowerCase())) {
      return;
    }
  }

  static Future<UserModel?> getCurrentUserModel() async {
    await _delay();
    return currentUser;
  }

  static Stream<UserModel?> watchCurrentUserModel() {
    return changes.startWith(null).asyncMap((_) => getCurrentUserModel());
  }

  static Future<Map<String, dynamic>> getStudentProfile(String uid) async {
    await _delay();
    return Map<String, dynamic>.from(MockData.studentProfiles[uid] ?? {});
  }

  static Stream<Map<String, dynamic>> watchStudentProfile(String uid) {
    return changes.startWith(null).asyncMap((_) => getStudentProfile(uid));
  }

  static Future<void> updateStudentProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    await _delay();
    final base = MockData.studentProfiles[uid] ?? <String, dynamic>{};
    base.addAll(updates);
    MockData.studentProfiles[uid] = base;
    _notify();
  }

  static Future<void> submitLeaveRequest(LeaveRequestModel request) async {
    await _delay();
    MockData.leaveRequests.add(
      LeaveRequestModel(
        id: 'leave-${DateTime.now().millisecondsSinceEpoch}',
        userId: request.userId,
        startDate: request.startDate,
        endDate: request.endDate,
        reason: request.reason,
        status: request.status,
        leaveType: request.leaveType,
        approvalManager: request.approvalManager,
        createdAt: DateTime.now(),
      ),
    );
    _notify();
  }

  static Stream<List<LeaveRequestModel>> watchMyLeaveRequests(String userId) {
    return changes.startWith(null).map((_) => MockData.leaveRequests
        .where((e) => e.userId == userId)
        .toList(growable: false));
  }

  static Stream<List<LeaveRequestModel>> watchPendingLeaves() {
    return changes.startWith(null).map((_) => MockData.leaveRequests
        .where((e) => e.status == LeaveRequestStatus.pending)
        .toList(growable: false));
  }

  static Future<void> cancelLeaveRequest(String requestId) async {
    await _delay();
    MockData.leaveRequests.removeWhere((e) => e.id == requestId);
    _notify();
  }

  static Future<void> updateLeaveStatus(
      String id, LeaveRequestStatus status) async {
    await _delay();
    final index = MockData.leaveRequests.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final req = MockData.leaveRequests[index];
    MockData.leaveRequests[index] = LeaveRequestModel(
      id: req.id,
      userId: req.userId,
      startDate: req.startDate,
      endDate: req.endDate,
      reason: req.reason,
      status: status,
      leaveType: req.leaveType,
      approvalManager: req.approvalManager,
      createdAt: req.createdAt,
    );
    _notify();
  }

  static Future<void> bookToken(FoodTokenModel token) async {
    await _delay();
    MockData.foodTokens.add(
      FoodTokenModel(
        id: 'token-${DateTime.now().millisecondsSinceEpoch}',
        userId: token.userId,
        itemName: token.itemName,
        itemPrice: token.itemPrice,
        quantity: token.quantity,
        totalPrice: token.totalPrice,
        mealSlot: token.mealSlot,
        scheduledDate: token.scheduledDate,
        status: token.status,
        createdAt: DateTime.now(),
      ),
    );
    _notify();
  }

  static Stream<List<FoodTokenModel>> watchMyTokens(String userId) {
    return changes.startWith(null).map((_) => MockData.foodTokens
        .where((e) => e.userId == userId)
        .toList(growable: false));
  }

  static Future<void> placeTShirtOrder(TShirtOrderModel order) async {
    await _delay();
    MockData.tshirtOrders.add(
      TShirtOrderModel(
        id: 'ts-${DateTime.now().millisecondsSinceEpoch}',
        userId: order.userId,
        type: order.type,
        size: order.size,
        quantity: order.quantity,
        pricePerUnit: order.pricePerUnit,
        totalPrice: order.totalPrice,
        status: order.status,
        createdAt: DateTime.now(),
      ),
    );
    _notify();
  }

  static Stream<List<TShirtOrderModel>> watchMyTShirtOrders(String userId) {
    return changes.startWith(null).map((_) => MockData.tshirtOrders
        .where((e) => e.userId == userId)
        .toList(growable: false));
  }

  static Future<void> submitComplaint(ComplaintModel complaint) async {
    await _delay();
    MockData.complaints.add(
      ComplaintModel(
        id: 'cmp-${DateTime.now().millisecondsSinceEpoch}',
        userId: complaint.userId,
        title: complaint.title,
        description: complaint.description,
        status: complaint.status,
        createdAt: DateTime.now(),
      ),
    );
    _notify();
  }

  static Stream<List<ComplaintModel>> watchComplaints() {
    return changes.startWith(null).map((_) => MockData.complaints);
  }

  static Stream<List<ComplaintModel>> watchMyComplaints(String userId) {
    return changes.startWith(null).map((_) => MockData.complaints
        .where((c) => c.userId == userId)
        .toList(growable: false));
  }

  static Future<void> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
  }) async {
    await _delay();
    final i = MockData.complaints.indexWhere((c) => c.id == complaintId);
    if (i == -1) return;
    final c = MockData.complaints[i];
    MockData.complaints[i] = ComplaintModel(
      id: c.id,
      userId: c.userId,
      title: c.title,
      description: c.description,
      status: status,
      createdAt: c.createdAt,
    );
    _notify();
  }

  static Future<void> registerDayEntry(DayEntryModel entry) async {
    await _delay();
    MockData.dayEntries.add(
      DayEntryModel(
        id: 'day-${DateTime.now().millisecondsSinceEpoch}',
        userId: entry.userId,
        passNumber: entry.passNumber,
        studentName: entry.studentName,
        rollNumber: entry.rollNumber,
        roomNumber: entry.roomNumber,
        programme: entry.programme,
        visitDate: entry.visitDate,
        timeSlot: entry.timeSlot,
        visitors: entry.visitors,
        status: entry.status,
        createdAt: DateTime.now(),
      ),
    );
    _notify();
  }

  static Stream<List<DayEntryModel>> watchMyDayEntries(String userId) {
    return changes.startWith(null).map((_) => MockData.dayEntries
        .where((e) => e.userId == userId)
        .toList(growable: false));
  }

  static Future<List<Map<String, dynamic>>> getMenuForSlot(
      String mealSlot) async {
    await _delay();
    return List<Map<String, dynamic>>.from(
      MockData.messMenuBySlot[mealSlot] ?? const <Map<String, dynamic>>[],
    );
  }

  static Future<bool> hasMealToken({
    required String userId,
    required DateTime date,
    required String mealSlot,
  }) async {
    await _delay();
    return MockData.foodTokens.any((t) {
      if (t.userId != userId || t.scheduledDate == null) return false;
      final d = t.scheduledDate!;
      return d.year == date.year &&
          d.month == date.month &&
          d.day == date.day &&
          (t.mealSlot ?? '').toLowerCase() == mealSlot.toLowerCase() &&
          t.status == FoodTokenStatus.active;
    });
  }

  static Future<List<Map<String, dynamic>>> getStudents() async {
    await _delay();
    return List<Map<String, dynamic>>.from(MockData.students);
  }

  static Future<Map<String, int>> getAdminMetrics() async {
    await _delay();
    final totalStudents =
        MockData.users.where((u) => u.role == UserRole.student).length;
    final totalRooms = MockData.students
        .map((s) => (s['roomId'] ?? '').toString())
        .where((room) => room.isNotEmpty)
        .toSet()
        .length;
    final pendingLeaves = MockData.leaveRequests
        .where((r) => r.status == LeaveRequestStatus.pending)
        .length;
    final openComplaints = MockData.complaints
        .where((c) =>
            c.status == ComplaintStatus.pending ||
            c.status == ComplaintStatus.inProgress)
        .length;

    return {
      'totalStudents': totalStudents,
      'totalRooms': totalRooms,
      'pendingLeaves': pendingLeaves,
      'openComplaints': openComplaints,
    };
  }

  static Stream<List<Map<String, dynamic>>> watchNotices() {
    return changes
        .startWith(null)
        .map((_) => List<Map<String, dynamic>>.from(MockData.notices));
  }

  static Future<void> addNotice(Map<String, dynamic> notice) async {
    await _delay();
    MockData.notices.add({
      'id': 'notice-${DateTime.now().millisecondsSinceEpoch}',
      ...notice,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    });
    _notify();
  }

  static Future<void> deleteNotice(String noticeId) async {
    await _delay();
    MockData.notices.removeWhere((n) => n['id'] == noticeId);
    _notify();
  }
}

extension _StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
