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
  final status = "Preparing".obs;
  
  // Static Charger Details
  final stationIdLabel = "ID: ...".obs;
  final maxPowerLabel = "... kW".obs;
  final connectorTypeLabel = "...".obs;
  
  // Full session details for Bill Summary
  final finalSessionData = <String, dynamic>{}.obs;

  bool _isFinalizing = false;
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
              
              // Bind SOC from backend
              // Logic Update: For prepaid sessions (finite amount), we prefer the calculated 
              // "Session Progress %" over the vehicle SOC, unless the user explicitly wants vehicle SOC.
              // Given the requirement "check calculation", we prioritize calculation here.
              if (initialAmount > 0 && initialAmount != double.infinity) {
                  _calculateSoC();
              } else if (data['soc'] != null) {
                  _updateSoc(data['soc']);
              } else {
                  _calculateSoC();
              }

              // Update Status
              if (data['charger_status'] != null) {
                   status.value = data['charger_status'];
              }

              // Check if session is already completed (e.g. resumed after stop)
              if (data['charger_status'] == 'Completed' || data['charger_status'] == 'completed') {
                  print("Session is already completed. Finalizing...");
                  handleSessionCompleted(data);
              }
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
    // status.value = "Charging"; // Removed: Don't force charging status

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
              // Only update if we are NOT in prepaid mode (handled below)
              if (initialAmount <= 0 || initialAmount == double.infinity) {
                 _updateSoc(payload['soc']);
              }
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
            
            // Logic Update: Prioritize calculated Session Progress for prepaid sessions
            if (initialAmount > 0 && initialAmount != double.infinity) {
                _calculateSoC();
            } else if (payload['soc'] != null) {
              _updateSoc(payload['soc']);
            } else {
               _calculateSoC();
            }
            
            // Force UI update by triggering value change (primitive refresh can be flaky in tight loops)
            // Even if value is same, we want to notify listeners
            soc.value = soc.value; 
            energyDelivered.value = energyDelivered.value;
            currentCost.value = currentCost.value;
            currentPower.value = currentPower.value;
            
            soc.refresh();
            energyDelivered.refresh();
            currentCost.refresh();
            currentPower.refresh();

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

  void handleSessionCompleted(dynamic data, {bool force = false}) {
    print("Handling Session Completed: $data");
    
    // Prepare new data map
    Map<String, dynamic> newData = Map<String, dynamic>.from(data);

    // If we already have finalized data, we should be careful not to overwrite valid data with incomplete data
    // (e.g. if polling returns stale data after WebSocket provided full data)
    if (status.value == "Completed" && finalSessionData.isNotEmpty) {
        // 1. Protect Stop Time: Don't overwrite existing stop_time with null
        if (finalSessionData['stop_time'] != null && newData['stop_time'] == null) {
             newData['stop_time'] = finalSessionData['stop_time'];
        }
        
        // 2. Protect Cost: Don't overwrite non-zero cost with zero
        double currentAmt = (finalSessionData['consumed_amount'] as num?)?.toDouble() ?? 0.0;
        double newAmt = (newData['consumed_amount'] as num?)?.toDouble() ?? 0.0;
        if (currentAmt > 0 && newAmt == 0) {
             newData['consumed_amount'] = finalSessionData['consumed_amount'];
             newData['cost'] = finalSessionData['cost'];
             newData['unit_consumed'] = finalSessionData['unit_consumed'];
        }
    }
    
    finalSessionData.value = newData;
    
    // Fix for "Empty Stop Time" race condition
    // If 'stop_time' is missing but 'timestamp' exists (from CDR event), use it.
    // Also check 'modified_date' as a fallback since the backend updates it on completion.
    if (finalSessionData['stop_time'] == null) {
       if (finalSessionData['timestamp'] != null) {
          finalSessionData['stop_time'] = finalSessionData['timestamp'];
       } else if (finalSessionData['modified_date'] != null) {
          finalSessionData['stop_time'] = finalSessionData['modified_date'];
       }
    }
    
    // Update display values if present
    if (data['unit_consumed'] != null) {
        energyDelivered.value = (data['unit_consumed'] / 1000.0); // Wh -> kWh
    }
    if (data['consumed_amount'] != null) {
        currentCost.value = (data['consumed_amount'] as num).toDouble();
    } else if (data['cost'] != null) {
        currentCost.value = (data['cost'] as num).toDouble();
    }

    // Only trigger navigation if not already completed
    if (status.value != "Completed") {
        // Check for essential data
        bool hasStopTime = finalSessionData['stop_time'] != null;
        
        if (hasStopTime || force) {
            finalizeSession();
        } else {
            print("Session data received but missing stop_time. Waiting for better data...");
        }
    }
  }

  void _updateSoc(dynamic rawVal) {
    if (rawVal == null) return;
    double val = (rawVal as num).toDouble();
    
    // Normalize SOC: If value is a ratio (<= 1.0 and > 0), convert to percentage
    if (val <= 1.0 && val > 0.0) {
      soc.value = val * 100;
    } else {
      soc.value = val;
    }
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
    if (_isFinalizing || status.value == "Completed") return;
    _isFinalizing = true;

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

    // Start polling for completion immediately
    // Check every 2 seconds, up to 10 times (20 seconds)
    int attempts = 0;
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      attempts++;
      
      // If already completed (e.g. via WebSocket), stop polling
      if (status.value == "Completed") {
        timer.cancel();
        return;
      }

      print("Polling for session completion (Attempt $attempts)...");
      bool isCompleted = await _checkCompletionStatus();
      
      if (isCompleted) {
        timer.cancel();
      } else if (attempts >= 10) {
        timer.cancel();
        print("Polling timeout. Forcing finish.");
        // Final attempt to get data, or just close
        await _fetchFinalDataAndFinish();
      }
    });
  }

  Future<bool> _checkCompletionStatus() async {
      try {
          // 1. Check History (most reliable for completed sessions)
          final historyResp = await _apiProvider.get('/charging/history');
          if (historyResp['error'] == false && historyResp['data'] != null) {
              final List history = historyResp['data'];
              final session = history.firstWhere(
                  (s) => s['session_id'].toString() == sessionId.toString(),
                  orElse: () => null
              );
              
              if (session != null) {
                  print("Found session in history via polling: $session");
                  handleSessionCompleted(session);
                  return status.value == "Completed";
              }
          }

          // 2. Check Active Session (to see if status changed to Completed)
          final activeResp = await _apiProvider.get('/charging/active-session');
          if (activeResp['data'] != null && activeResp['data']['session_id'].toString() == sessionId.toString()) {
               final data = activeResp['data'];
               if (data['charger_status'] == 'Completed' || data['charger_status'] == 'completed') {
                   print("Found completed status in active-session endpoint");
                   handleSessionCompleted(data);
                   return status.value == "Completed";
               }
          }
          
          return false;
      } catch (e) {
          print("Error checking completion status: $e");
          return false;
      }
  }

  Future<void> _fetchFinalDataAndFinish() async {
      try {
          // 1. Try fetching active session first (in case it's still closing)
          final activeResp = await _apiProvider.get('/charging/active-session');
          if (activeResp['data'] != null && activeResp['data']['session_id'].toString() == sessionId.toString()) {
               final data = activeResp['data'];
               // If it's still 'active' but we timed out stopping, maybe force close locally?
               // But usually we want 'completed' data.
               // Let's check if the status in DB says completed.
               if (data['charger_status'] == 'Completed' || data['charger_status'] == 'completed') {
                   handleSessionCompleted(data, force: true);
                   return;
               }
          }

          // 2. If not in active (or not completed there), check history
          final historyResp = await _apiProvider.get('/charging/history');
          if (historyResp['error'] == false && historyResp['data'] != null) {
              final List history = historyResp['data'];
              final session = history.firstWhere(
                  (s) => s['session_id'].toString() == sessionId.toString(),
                  orElse: () => null
              );
              
              if (session != null) {
                  print("Found session in history: $session");
                  handleSessionCompleted(session, force: true);
                  return;
              }
          }
          
          // 3. If still nothing, just finish with what we have locally
          print("Could not fetch final data. Finishing with local values.");
          finalizeSession();
          
      } catch (e) {
          print("Error fetching final data: $e");
          finalizeSession();
      }
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
