import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_app/core/network/websocket_service.dart';
import 'package:user_app/core/controllers/session_controller.dart';
import 'package:user_app/app/modules/charging/views/bill_summary_view.dart';
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
  
  // Full session details for Bill Summary
  final finalSessionData = <String, dynamic>{}.obs;

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
      final wsUrl = "ws://192.168.0.57:3001?token=$token";

      _wsService = WebSocketService(wsUrl);
      _wsService?.onConnected = () {
        print("🟢 WS Connected to Charging Session");
      };

      _wsService?.stream.listen((data) {
        try {
          final decoded = jsonDecode(data.toString());
          final event = decoded['event'];
          final payload = decoded['data'];

          if (event == 'charging_progress') {
            // Matched with Backend
            // Payload: { energyConsumed: double, power: double, soc: double }

            if (payload['power'] != null) {
              currentPower.value = (payload['power'] / 1000.0); // W -> kW
            }

            if (payload['energyConsumed'] != null) {
              energyDelivered.value =
                  (payload['energyConsumed'] / 1000.0); // Wh -> kWh
            }

            // Update cost based on energy
            currentCost.value = energyDelivered.value * ratePerKwh;

            // Check limits
            if (currentCost.value >= initialAmount) {
              stopCharging();
            }
          } else if (event == 'session_completed') {
             // Handle completion
             final payload = decoded['data'];
             handleSessionCompleted(payload);
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

  void handleSessionCompleted(Map<String, dynamic> data) {
    if (status.value == "Completed") return;
    
    finalSessionData.value = data;
    
    // Update display values if present
    if (data['unit_consumed'] != null) {
        energyDelivered.value = (data['unit_consumed'] / 1000.0); // Wh -> kWh
    }
    if (data['consumed_amount'] != null) {
        currentCost.value = (data['consumed_amount'] as num).toDouble();
    } else if (data['cost'] != null) {
        currentCost.value = (data['cost'] as num).toDouble();
    }

    finalizeSession();
  }

  void finalizeSession() {
    status.value = "Completed";
    _timer?.cancel();
    _wsService?.disconnect();
    currentPower.value = 0;
    
    Get.off(() => BillSummaryView(controller: this));
  }

  Future<void> stopCharging() async {
    if (status.value == "Completed" || status.value == "Stopping") return;

    status.value = "Stopping";

    try {
      await _apiProvider.post('/charging/stop', {'session_id': sessionId});
    } catch (e) {
      print("Error stopping session: $e");
    }

    // Safety timeout: if no WS event in 5 seconds, finish locally
    Future.delayed(const Duration(seconds: 5), () {
       if (status.value != "Completed") {
           finalizeSession();
       }
    });
  }

  Future<void> downloadInvoice() async {
    try {
      final sessionController = Get.find<SessionController>();
      final token = sessionController.token.value;
      
      final url = '${ApiProvider.baseUrl}/charging/invoice/$sessionId?token=$token';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Error', 'Could not launch invoice download');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to download invoice: $e');
    }
  }
}
