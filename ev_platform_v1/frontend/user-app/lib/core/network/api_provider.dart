import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:user_app/core/controllers/session_controller.dart';

class ApiProvider {
  // Use 10.0.2.2 for Android emulator, localhost for iOS simulator
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.1.7:3000';
    }
    return 'http://192.168.1.7:3000';
  }

  final SessionController _sessionController = Get.find<SessionController>();

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders())
          .timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper for external APIs (like Google Maps)
  Future<dynamic> getDirect(
    Uri url, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('External API error: ${response.statusCode}');
      }
    } on TimeoutException {
      // Re-throw TimeoutException directly so controllers can handle it specifically
      rethrow;
    } catch (e) {
      // Don't wrap if it's already an Exception, just log and rethrow or wrap if needed
      if (e is TimeoutException) rethrow;
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _getHeaders(),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: _getHeaders(),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders())
          .timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_sessionController.isLoggedIn.value) {
      headers['Authorization'] = 'Bearer ${_sessionController.token.value}';
    }
    return headers;
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      _sessionController.clearSession();
      Get.offAllNamed('/login');
      throw Exception('Unauthorized');
    } else {
      throw Exception('Error: ${response.statusCode} ${response.body}');
    }
  }
}
