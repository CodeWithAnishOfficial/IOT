import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> init() async {
    debugPrint('NotificationService: Web implementation - skipping initialization');
  }

  Future<void> requestPermissions() async {
    debugPrint('NotificationService: Web implementation - skipping permission request');
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('NotificationService: Web implementation - showNotification called (no-op)');
  }

  Future<void> showChargingCompleteNotification({
    required double energy,
    required double cost,
  }) async {
    debugPrint('NotificationService: Web implementation - showChargingCompleteNotification called (no-op)');
  }

  Future<void> showChargingFaultNotification({
    String? errorCode,
    double? energy,
    double? cost,
  }) async {
    debugPrint('NotificationService: Web implementation - showChargingFaultNotification called (no-op)');
  }
}
