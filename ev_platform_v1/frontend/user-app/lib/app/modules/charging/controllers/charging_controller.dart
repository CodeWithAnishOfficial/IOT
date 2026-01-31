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
  final voltage = 0.0.obs; // V
  final currentAmps = 0.0.obs; // A
  final soc = 0.0.obs; // Battery %
  final status = "Charging".obs;
  
  // Static Charger Details
  final stationIdLabel = "ID: ...".obs;
  final maxPowerLabel = "... kW".obs;
  final connectorTypeLabel = "...".obs;
  
  // Full session details for Bill Summary
  final finalSessionData = <String, dynamic>{}.obs;

  Timer? _timer;
  WebSocketService? _wsService;
  DateTime _startTime = DateTime.now();

  // Mock constants
  double ratePerKwh = 0.75; // Fetched from session details

  ChargingController({
    required this.connectorId,
    required this.initialAmount,
    required this.sessionId,
  });

  @override
  void onInit() {
    super.onInit();
    fetchSessionDetails();
    startSession();
  }

  Future<void> fetchSessionDetails() async {
      try {
          final response = await _apiProvider.get('/charging/active-session');
          if (response['error'] == false && response['data'] != null) {
              final data = response['data'];
              
              // 1. Restore Start Time
              if (data['start_time'] != null) {
                  _startTime = DateTime.parse(data['start_time']);
                  print("Restored session start time: $_startTime");
              }
              
              // 2. Restore Rate
              if (data['unit_price'] != null) {
                  ratePerKwh = (data['unit_price'] as num).toDouble();
              }

              // Bind Charger Details
              if (data['chargerDetails'] != null) {
                  final details = data['chargerDetails'];
                  stationIdLabel.value = "ID: ${details['charger_id'] ?? '...'}";
                  maxPowerLabel.value = "${details['max_power_kw'] ?? 0} kW";
                  connectorTypeLabel.value = details['connector_type']?.toString() ?? 'Unknown';
              }
              
              // Bind Initial Session Values if any (e.g. resuming)
              if (data['unit_consumed'] != null) {
                  energyDelivered.value = (data['unit_consumed'] / 1000.0);
              }
              if (data['consumed_amount'] != null) {
                  currentCost.value = (data['consumed_amount'] as num).toDouble();
              }
              
              _calculateSoC();
          }
      } catch (e) {
          print("Error fetching session details: $e");
      }
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
      // Construct WS URL dynamically from ApiProvider base URL
      final uri = Uri.parse(ApiProvider.baseUrl);
      final host = uri.host;
      final wsUrl = "ws://$host:3001?token=$token";
      
      print("Connecting to WS: $wsUrl");

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

            if (payload['soc'] != null) {
              soc.value = (payload['soc'] as num).toDouble();
            }
            
            if (payload['voltage'] != null) {
              voltage.value = (payload['voltage'] as num).toDouble();
            }
            
            if (payload['current'] != null) {
              currentAmps.value = (payload['current'] as num).toDouble();
            }

            if (payload['energyConsumed'] != null) {
              energyDelivered.value =
                  (payload['energyConsumed'] / 1000.0); // Wh -> kWh
            }

            // Update cost from backend if available, else fallback to local calc
            if (payload['cost'] != null) {
               currentCost.value = (payload['cost'] as num).toDouble();
            } else {
               currentCost.value = energyDelivered.value * ratePerKwh;
            }
            
            // Calculate simulated SoC based on payment progress
            _calculateSoC();

            // Check limits
            if (currentCost.value >= initialAmount) {
              stopCharging();
            }
          } else if (event == 'session_completed') {
             // Handle completion
             print("ChargingController: Received session_completed");
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

  void handleSessionCompleted(dynamic data) {
    print("Handling Session Completed: $data");
    
    // Safety check for status
    if (status.value == "Completed") return;
    
    finalSessionData.value = Map<String, dynamic>.from(data);
    
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

  void _calculateSoC() {
    if (initialAmount <= 0 || initialAmount == double.infinity) return;
    
    // Calculate total energy user can buy
    final maxEnergy = initialAmount / ratePerKwh;
    if (maxEnergy <= 0) return;
    
    // Calculate percentage
    double percentage = (energyDelivered.value / maxEnergy) * 100;
    
    // Clamp to 0-100
    if (percentage > 100) percentage = 100;
    if (percentage < 0) percentage = 0;
    
    soc.value = percentage;
  }

  void finalizeSession() {
    print("Finalizing session...");
    status.value = "Completed";
    _timer?.cancel();
    _wsService?.disconnect();
    currentPower.value = 0;
    
    // Ensure we are on the main thread and navigation works
    Future.delayed(const Duration(milliseconds: 100), () {
        Get.off(() => BillSummaryView(controller: this));
    });
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
