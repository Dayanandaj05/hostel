import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../domain/entities/day_entry_model.dart';
import '../../domain/repositories/day_entry_repository.dart';

class DayEntryController extends ChangeNotifier {
  final DayEntryRepository _repository;

  bool _isSubmitting = false;
  bool _isLoadingRegistrations = false;
  String? _errorMessage;
  String? _successMessage;
  List<DayEntryModel> _myRegistrations = [];
  StreamSubscription? _subscription;

  DayEntryController(this._repository);

  bool get isSubmitting => _isSubmitting;
  bool get isLoadingRegistrations => _isLoadingRegistrations;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<DayEntryModel> get myRegistrations => _myRegistrations;

  void startWatchingRegistrations(String userId) {
    _isLoadingRegistrations = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _repository.watchMyRegistrations(userId).listen(
      (registrations) {
        _myRegistrations = registrations;
        _isLoadingRegistrations = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoadingRegistrations = false;
        notifyListeners();
      },
    );
  }

  void stopWatchingRegistrations() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<bool> registerDayEntry({
    required String userId,
    required String studentName,
    required String rollNumber,
    required String roomNumber,
    required String programme,
    required DateTime visitDate,
    required String timeSlot,
    required List<DayEntryVisitor> visitors,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final passNumber = 'DEP-${visitDate.year}-${(Random().nextInt(90000) + 10000)}';
      
      final entry = DayEntryModel(
        userId: userId,
        passNumber: passNumber,
        studentName: studentName,
        rollNumber: rollNumber,
        roomNumber: roomNumber,
        programme: programme,
        visitDate: visitDate,
        timeSlot: timeSlot,
        visitors: visitors,
        status: 'pending',
      );

      await _repository.registerDayEntry(entry);
      
      _successMessage = 'Registration successful! Your pass number is $passNumber';
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopWatchingRegistrations();
    super.dispose();
  }
}
