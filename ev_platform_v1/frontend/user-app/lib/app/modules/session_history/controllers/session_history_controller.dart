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

  Future<void> fetchSessions() async {
    try {
      isLoading.value = true;
      // Using new endpoint /charging/history
      final response = await _apiProvider.get('/charging/history');
      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        final allSessions = data.map((e) => ChargingSession.fromJson(e)).toList();
        
        // Filter: Only show completed/stopped/failed sessions
        // Exclude 'Charging', 'Pending', 'Started', etc.
        sessions.value = allSessions.where((s) {
           final st = s.status.toLowerCase();
           return st == 'completed' || 
                  st == 'finished' || 
                  st == 'stopped' || 
                  st == 'failed';
        }).toList();
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
                
                // Update specific session if sessionId is present
                if (jsonData['sessionId'] != null) {
                  final sId = jsonData['sessionId'].toString();
                  final index = sessions.indexWhere((s) => s.sessionId == sId);
                  
                  if (index != -1) {
                    final oldSession = sessions[index];
                    
                    String newStatus = oldSession.status;
                    if (jsonData['status'] != null) {
                       newStatus = jsonData['status'];
                       // Update banner if it's the latest relevant status
                       currentStatus.value = 'Status: $newStatus';
                    }
                    
                    double newEnergy = oldSession.totalEnergy;
                    if (jsonData['energyConsumed'] != null) {
                      newEnergy = (jsonData['energyConsumed'] as num).toDouble();
                    }
                    
                    // Replace with new object to trigger UI update for that item
                    sessions[index] = ChargingSession(
                      sessionId: oldSession.sessionId,
                      transactionId: oldSession.transactionId,
                      chargerId: oldSession.chargerId,
                      connectorId: oldSession.connectorId,
                      userId: oldSession.userId,
                      startTime: oldSession.startTime,
                      stopTime: oldSession.stopTime,
                      meterStart: oldSession.meterStart,
                      meterStop: oldSession.meterStop,
                      totalEnergy: newEnergy,
                      cost: oldSession.cost, // Assuming cost isn't sent in progress, or add logic if it is
                      status: newStatus,
                    );
                  } else {
                    // New session? Refresh list
                     if (jsonData['status'] == 'active') {
                        fetchSessions();
                     }
                  }
                } else if (jsonData['status'] != null) {
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
