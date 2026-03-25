import 'package:flutter/foundation.dart';

/// Offline notification shim used when backend services are disabled.
class NotificationService {
  static Future<void> initialize() async {
    debugPrint('NotificationService: offline mode initialize');
  }

  static Future<void> updateToken(String uid) async {
    debugPrint(
        'NotificationService: skip token update for $uid (offline mode)');
  }

  static Future<void> subscribeToRole(String role) async {
    debugPrint('NotificationService: skip subscribe role=$role (offline mode)');
  }

  static Future<void> unsubscribeAll() async {
    debugPrint('NotificationService: skip unsubscribe (offline mode)');
  }
}
