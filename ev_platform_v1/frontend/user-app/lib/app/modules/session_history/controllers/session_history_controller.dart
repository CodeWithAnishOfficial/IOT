import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_app/core/controllers/session_controller.dart';
import 'package:user_app/app/modules/session_history/domain/models/charging_session.dart';
import 'package:user_app/core/network/api_provider.dart';

class SessionHistoryController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final SessionController _sessionController = Get.find<SessionController>();

  final sessions = <ChargingSession>[].obs;
  final isLoading = false.obs;

  // Real-time status
  final currentStatus = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSessions();
    connectToSse();
  }
  
  @override
  void onReady() {
    super.onReady();
    // Re-fetch when view becomes ready to ensure data is fresh
    fetchSessions();
  }

  Future<void> fetchSessions() async {
    try {
      isLoading.value = true;
      // Using new endpoint /charging/history
      final response = await _apiProvider.get('/charging/history');
      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        final allSessions = data.map((e) => ChargingSession.fromJson(e)).toList();
        
        // Filter: Only show completed/stopped/failed sessions, including 'stopping'
        sessions.value = allSessions.where((s) {
           final st = s.status.toLowerCase();
           return st == 'completed' || 
                  st == 'finished' || 
                  st == 'stopped' || 
                  st == 'stopping' ||
                  st == 'failed';
        }).toList();
        
        // Ensure strictly sorted by start time (newest first)
        sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      }
    } catch (e) {
      print('Error fetching sessions: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> requestInvoice(String sessionId) async {
    try {
      final token = _sessionController.token.value;
      if (token.isEmpty) {
        Get.snackbar('Error', 'Not authenticated');
        return;
      }
      
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

  void connectToSse() async {
    try {
      final token = _sessionController.token.value;
      if (token.isEmpty) return;

      final client = http.Client();
      final request = http.Request(
        'GET',
        Uri.parse('${ApiProvider.baseUrl}/sse/connect'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await client.send(request);

      response.stream.transform(utf8.decoder).listen((data) {
        // SSE format: data: {...}
        if (data.contains('data:')) {
          // Very basic parsing
          // Real SSE parsers handle splitting by \n\n
          // For MVP:
          final lines = data.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final jsonStr = line.substring(6);
              try {
                final jsonData = json.decode(jsonStr);
                
                // Update specific session if sessionId is present (Handle both camelCase and snake_case)
                final sId = jsonData['sessionId']?.toString() ?? jsonData['session_id']?.toString();
                
                if (sId != null) {
                  final index = sessions.indexWhere((s) => s.sessionId == sId);
                  
                  if (index != -1) {
                    final oldSession = sessions[index];
                    
                    String newStatus = oldSession.status;
                    final statusVal = jsonData['status'] ?? jsonData['charger_status'];
                    if (statusVal != null) {
                       newStatus = statusVal;
                       // Update banner if it's the latest relevant status
                       currentStatus.value = 'Status: $newStatus';
                    }
                    
                    double newEnergy = oldSession.totalEnergy;
                    if (jsonData['energyConsumed'] != null) {
                      newEnergy = (jsonData['energyConsumed'] as num).toDouble();
                    } else if (jsonData['unit_consumed'] != null) {
                      newEnergy = (jsonData['unit_consumed'] as num).toDouble();
                    }
                    
                    double newCost = oldSession.cost;
                    if (jsonData['cost'] != null) {
                       newCost = (jsonData['cost'] as num).toDouble();
                    } else if (jsonData['consumed_amount'] != null) {
                       newCost = (jsonData['consumed_amount'] as num).toDouble();
                    }
                    
                    DateTime? newStopTime = oldSession.stopTime;
                    if (jsonData['stop_time'] != null) {
                       newStopTime = DateTime.parse(jsonData['stop_time']);
                    } else if (jsonData['modified_date'] != null && 
                              (newStatus.toLowerCase() == 'completed' || newStatus.toLowerCase() == 'finished')) {
                       // Fallback to modified_date if stop_time is missing but status is completed
                       newStopTime = DateTime.parse(jsonData['modified_date']);
                    }

                    double? newMeterStop = oldSession.meterStop;
                    if (jsonData['meter_stop'] != null) {
                       newMeterStop = (jsonData['meter_stop'] as num).toDouble();
                    }

                    // Replace with new object to trigger UI update for that item
                    sessions[index] = ChargingSession(
                      sessionId: oldSession.sessionId,
                      transactionId: oldSession.transactionId,
                      chargerId: oldSession.chargerId,
                      stationName: oldSession.stationName,
                      connectorId: oldSession.connectorId,
                      userId: oldSession.userId,
                      startTime: oldSession.startTime,
                      stopTime: newStopTime,
                      meterStart: oldSession.meterStart,
                      meterStop: newMeterStop,
                      totalEnergy: newEnergy,
                      cost: newCost,
                      status: newStatus,
                    );
                  } else {
                    // New session or not in list?
                    // If it's a "Completed" event for a session we don't have (maybe because it was 'active' and filtered out)
                    // We should trigger a fetch
                    final statusVal = jsonData['status'] ?? jsonData['charger_status'];
                    if (statusVal != null && ['completed', 'stopped', 'finished'].contains(statusVal.toString().toLowerCase())) {
                        fetchSessions();
                    }
                  }
                } else if (jsonData['status'] != null || jsonData['charger_status'] != null) {
                   // Fallback for global status updates without sessionId
                   currentStatus.value = 'Status: ${jsonData['status']}';
                   fetchSessions();
                }
              } catch (e) {
                // ignore keepalive or connect messages
              }
            }
          }
        }
      });
    } catch (e) {
      print('SSE Error: $e');
    }
  }
}
