import 'dart:async';
import 'package:flutter/material.dart';

import 'package:hostel_app/features/leave/domain/entities/leave_request_model.dart';
import 'package:hostel_app/features/leave/domain/repositories/leave_request_repository.dart';

class LeaveRequestController extends ChangeNotifier {
  LeaveRequestController(this._repository);

  final LeaveRequestRepository _repository;

  bool _isSubmitting = false;
  bool _isLoadingHistory = false;
  bool _isCancelling = false;
  String? _errorMessage;
  String? _successMessage;

  List<LeaveRequestModel> _leaveHistory = [];
  StreamSubscription? _historySubscription;

  bool get isSubmitting => _isSubmitting;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isCancelling => _isCancelling;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<LeaveRequestModel> get leaveHistory => _leaveHistory;

  void startWatchingHistory(String userId) {
    stopWatchingHistory();
    _isLoadingHistory = true;
    notifyListeners();

    _historySubscription = _repository.watchMyLeaveRequests(userId).listen(
      (requests) {
        // Sort client-side to avoid Firestore index requirement
        final sorted = List<LeaveRequestModel>.from(requests)
          ..sort((a, b) {
            final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
        _leaveHistory = sorted;
        _isLoadingHistory = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        String msg = 'Failed to load leave history.';
        final errorStr = error.toString().toLowerCase();
        if (errorStr.contains('permission-denied')) {
          msg = 'Permission denied. Please check your role.';
        } else if (errorStr.contains('unavailable') || errorStr.contains('network')) {
          msg = 'Network unavailable. Please check your connection.';
        }
        _errorMessage = msg;
        _isLoadingHistory = false;
        notifyListeners();
      },
    );
  }

  void stopWatchingHistory() {
    _historySubscription?.cancel();
    _historySubscription = null;
  }

  Future<bool> submitLeaveRequest({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? leaveType,
    String? approvalManager,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    if (endDate.isBefore(startDate)) {
      _isSubmitting = false;
      _errorMessage = 'End date cannot be before start date.';
      notifyListeners();
      return false;
    }

    if (reason.trim().isEmpty) {
      _isSubmitting = false;
      _errorMessage = 'Reason is required.';
      notifyListeners();
      return false;
    }

    final request = LeaveRequestModel(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      reason: reason.trim(),
      status: LeaveRequestStatus.pending,
      leaveType: leaveType,
      approvalManager: approvalManager,
    );

    try {
      await _repository.submitLeaveRequest(request);
      _successMessage = 'Leave request submitted successfully.';
      return true;
    } on LeaveRequestException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to submit leave request.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> cancelLeave(String requestId) async {
    _isCancelling = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repository.cancelLeaveRequest(requestId);
      _successMessage = 'Leave request cancelled successfully.';
      return true;
    } on LeaveRequestException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to cancel leave request.';
      return false;
    } finally {
      _isCancelling = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopWatchingHistory();
    super.dispose();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
