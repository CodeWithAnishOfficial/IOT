import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:user_app/core/controllers/session_controller.dart';
import 'package:user_app/feature/session_history/domain/models/charging_session.dart';
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
      final response = await _apiProvider.get('/profile/sessions');
      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        sessions.value = data.map((e) => ChargingSession.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching sessions: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> requestInvoice(String sessionId) async {
    try {
      final response = await _apiProvider.post(
        '/profile/sessions/$sessionId/invoice',
        {},
      );
      Get.snackbar('Success', response['message']);
    } catch (e) {
      Get.snackbar('Error', 'Failed to send invoice');
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
                // Process update
                // If status update
                if (jsonData['status'] != null) {
                  currentStatus.value = 'Status: ${jsonData['status']}';
                  // If session updated, refresh list
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
