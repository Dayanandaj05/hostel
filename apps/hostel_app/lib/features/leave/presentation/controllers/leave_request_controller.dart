import 'package:flutter/material.dart';

import '../../domain/entities/leave_request_model.dart';
import '../../domain/repositories/leave_request_repository.dart';

class LeaveRequestController extends ChangeNotifier {
  LeaveRequestController(this._repository);

  final LeaveRequestRepository _repository;

  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<bool> submitLeaveRequest({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
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
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      endDate: DateTime(endDate.year, endDate.month, endDate.day),
      reason: reason.trim(),
      status: LeaveRequestStatus.pending,
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

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
