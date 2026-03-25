import 'package:flutter/material.dart';

class NavbarProvider extends ChangeNotifier {
  int _studentCurrentIndex = 0;
  int _wardenCurrentIndex = 0;
  int _adminCurrentIndex = 0;

  // Store last accessed tab per role (to restore when returning from secondary screens)
  int _lastStudentTab = 0;
  int _lastWardenTab = 0;
  int _lastAdminTab = 0;

  int get studentCurrentIndex => _studentCurrentIndex;
  int get wardenCurrentIndex => _wardenCurrentIndex;
  int get adminCurrentIndex => _adminCurrentIndex;

  int get lastStudentTab => _lastStudentTab;
  int get lastWardenTab => _lastWardenTab;
  int get lastAdminTab => _lastAdminTab;

  void setStudentTab(int index) {
    _studentCurrentIndex = index;
    _lastStudentTab = index;
    notifyListeners();
  }

  void setWardenTab(int index) {
    _wardenCurrentIndex = index;
    _lastWardenTab = index;
    notifyListeners();
  }

  void setAdminTab(int index) {
    _adminCurrentIndex = index;
    _lastAdminTab = index;
    notifyListeners();
  }

  // Restore the last tab when returning from secondary screens
  void restoreStudentTab() {
    _studentCurrentIndex = _lastStudentTab;
    notifyListeners();
  }

  void restoreWardenTab() {
    _wardenCurrentIndex = _lastWardenTab;
    notifyListeners();
  }

  void restoreAdminTab() {
    _adminCurrentIndex = _lastAdminTab;
    notifyListeners();
  }

  // Quick check for current tab across all roles
  int getCurrentTabForRole(String role) {
    return switch (role.toLowerCase()) {
      'student' => _studentCurrentIndex,
      'warden' => _wardenCurrentIndex,
      'admin' => _adminCurrentIndex,
      _ => 0,
    };
  }
}
