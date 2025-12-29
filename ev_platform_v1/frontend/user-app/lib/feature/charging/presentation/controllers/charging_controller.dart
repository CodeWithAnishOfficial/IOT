import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:user_app/core/Networks/websocket_service.dart';
import 'package:user_app/core/controllers/session_controller.dart';

import 'package:user_app/core/network/api_provider.dart';

class ChargingController extends GetxController {
  final String connectorId;
  final double initialAmount;
  final String sessionId;
  
  final ApiProvider _apiProvider = ApiProvider();
  
  // Observable state
  final durationString = "00:00:00".obs;
  final energyDelivered = 0.0.obs;
  final currentCost = 0.0.obs;
  final currentPower = 0.0.obs; // kW
  final status = "Charging".obs;
  
  Timer? _timer;
  WebSocketService? _wsService;
  final DateTime _startTime = DateTime.now();
  
  // Mock constants
  final double ratePerKwh = 0.75; // $0.75 or ₹0.75 based on locale
  
  ChargingController({
    required this.connectorId,
    required this.initialAmount,
    required this.sessionId,
  });

  @override
  void onInit() {
    super.onInit();
    startSession();
  }

  @override
  void onClose() {
    _timer?.cancel();
    _wsService?.disconnect();
    super.onClose();
  }

  void startSession() {
    // 1. Start Local Timer for Duration (Visual)
    status.value = "Charging";
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final difference = now.difference(_startTime);
      
      // Update Timer String
      final hours = difference.inHours.toString().padLeft(2, '0');
      final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
      durationString.value = "$hours:$minutes:$seconds";
    });

    // 2. Connect to WebSocket for Real-time Data
    try {
      final sessionController = Get.find<SessionController>();
      final token = sessionController.token.value;
      if (token.isEmpty) {
        print("WS Error: No token found");
        return;
      }

      // Using User API Port 3001 for WebSocket
      // NOTE: Ensure device is on same network and IP is reachable
      final wsUrl = "ws://192.168.1.9:3001?token=$token";
      
      _wsService = WebSocketService(wsUrl);
      _wsService?.onConnected = () {
        print("🟢 WS Connected to Charging Session");
      };

      _wsService?.stream.listen((data) {
        try {
          final decoded = jsonDecode(data.toString());
          final event = decoded['event'];
          final payload = decoded['data'];

          if (event == 'charging_progress') { // Matched with Backend
             // Payload: { energyConsumed: double, power: double, soc: double }
             
             if (payload['power'] != null) {
               currentPower.value = (payload['power'] / 1000.0); // W -> kW
             }
             
             if (payload['energyConsumed'] != null) {
               energyDelivered.value = (payload['energyConsumed'] / 1000.0); // Wh -> kWh
             }
             
             // Update cost based on energy
             currentCost.value = energyDelivered.value * ratePerKwh;
             
             // Check limits
             if (currentCost.value >= initialAmount) {
                stopCharging();
             }
             
          } else if (event == 'session_completed') {
             stopCharging();
          }
        } catch (e) {
          print("WS Parse Error: $e");
        }
      });
      
      _wsService?.connect();
      
    } catch (e) {
      print("WS Connection Error: $e");
    }
  }

  Future<void> stopCharging() async {
    if (status.value == "Completed" || status.value == "Stopping") return;

    status.value = "Stopping";
    
    try {
        await _apiProvider.post('/charging/stop', {
            'session_id': sessionId
        });
    } catch (e) {
        print("Error stopping session: $e");
    }

    _timer?.cancel();
    _wsService?.disconnect();
    status.value = "Completed";
    currentPower.value = 0;
    
    Get.snackbar("Session Ended", "Charging complete. Final cost: ${currentCost.value.toStringAsFixed(2)}");
  }
}
