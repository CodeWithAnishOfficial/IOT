import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/utils/debug/build_guard.dart';

class ConnectivityController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  RxBool isConnected = true.obs;

  @override
  void onInit() {
    super.onInit();

    // Delay the initial check to ensure GetX is fully initialized
    Future.delayed(Duration(milliseconds: 500), () {
      checkConnection();
      _subscription =
          _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    });
  }

  Future<void> checkConnection() async {
    List<ConnectivityResult> result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    // Use BuildGuard to prevent state changes during build
    BuildGuard.runSafely(() {
      bool wasConnected = isConnected.value;
      isConnected.value = !result.contains(ConnectivityResult.none);

      // Only perform navigation if GetX is properly initialized and has a valid context
      if (Get.context == null) {
        debugPrint('GetX context not available, skipping navigation');
        return;
      }

      // Additional safety check
      try {
        // This will throw an error if navigation is not possible
        final _ = Get.currentRoute;
      } catch (e) {
        debugPrint('GetX navigation not ready: $e');
        return;
      }

      if (!isConnected.value) {
        // Navigate to NoInternetScreen if not already there
        try {
          if (Get.currentRoute != '/noInternet') {
            Get.toNamed('/noInternet');
          }
        } catch (e) {
          debugPrint('Navigation error: $e');
        }
      } else if (wasConnected != isConnected.value) {
        // Only navigate if connection status actually changed
        // If internet is back, pop the NoInternetScreen to resume previous state
        try {
          if (!wasConnected && Get.currentRoute == '/noInternet') {
             Get.back();
          }
        } catch (e) {
          debugPrint('Navigation error: $e');
        }
      }
    });
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}
