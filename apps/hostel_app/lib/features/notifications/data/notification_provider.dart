import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  final Map<String, int> _badgeCounts = {'notices': 0, 'leave': 0};

  Map<String, int> get badgeCounts => _badgeCounts;

  int getUnreadCount(String key) => _badgeCounts[key] ?? 0;

  void setUnreadCount(String key, int count) {
    _badgeCounts[key] = count;
    notifyListeners();
  }

  void incrementUnreadCount(String key) {
    _badgeCounts[key] = (_badgeCounts[key] ?? 0) + 1;
    notifyListeners();
  }

  void clearUnreadCount(String key) {
    _badgeCounts[key] = 0;
    notifyListeners();
  }
}
