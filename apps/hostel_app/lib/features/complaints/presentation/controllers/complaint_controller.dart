import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/complaint_model.dart';
import '../../domain/repositories/complaint_repository.dart';

class ComplaintController extends ChangeNotifier {
  ComplaintController(this._repository);

  final ComplaintRepository _repository;

  bool _isSubmitting = false;
  bool _isUpdating = false;
  String? _errorMessage;
  String? _successMessage;
  List<ComplaintModel> _complaints = [];
  StreamSubscription<List<ComplaintModel>>? _complaintsSubscription;

  bool get isSubmitting => _isSubmitting;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<ComplaintModel> get complaints => _complaints;

  Future<bool> submitComplaint({
    required String userId,
    required String title,
    required String description,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    if (title.trim().isEmpty || description.trim().isEmpty) {
      _isSubmitting = false;
      _errorMessage = 'Title and description are required.';
      notifyListeners();
      return false;
    }

    final complaint = ComplaintModel(
      id: '',
      userId: userId,
      title: title.trim(),
      description: description.trim(),
      status: ComplaintStatus.pending,
      createdAt: null,
    );

    try {
      await _repository.submitComplaint(complaint);
      _successMessage = 'Complaint submitted successfully.';
      return true;
    } on ComplaintException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to submit complaint.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void watchComplaints() {
    _complaintsSubscription?.cancel();
    _complaintsSubscription = _repository.watchComplaints().listen(
      (items) {
        _complaints = items;
        notifyListeners();
      },
      onError: (_) {
        _errorMessage = 'Unable to load complaints right now.';
        notifyListeners();
      },
    );
  }

  Future<void> updateStatus({
    required String complaintId,
    required ComplaintStatus status,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repository.updateComplaintStatus(
        complaintId: complaintId,
        status: status,
      );
      _successMessage = 'Complaint status updated.';
    } on ComplaintException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Failed to update complaint status.';
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    super.dispose();
  }
}
