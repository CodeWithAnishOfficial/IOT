import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:user_app/core/controllers/session_controller.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic data;

  ApiException(this.message, this.statusCode, [this.data]);

  @override
  String toString() => message;
}

class ApiProvider {
  // Use 10.0.2.2 for Android emulator, localhost for iOS simulator
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.1.9:3000';
    }
    return 'http://192.168.1.9:3000';
  }

  final SessionController _sessionController = Get.find<SessionController>();

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders())
          .timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } on SocketException {
      throw Exception('Connection refused: Server is unreachable');
    } on TimeoutException {
      throw Exception('Connection timed out');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('Connection refused: Server is unreachable');
      }
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
    } on SocketException {
      throw Exception('Connection refused: Server is unreachable');
    } on TimeoutException {
      throw Exception('Connection timed out');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('Connection refused: Server is unreachable');
      }
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
    } on SocketException {
      throw Exception('Connection refused: Server is unreachable');
    } on TimeoutException {
      throw Exception('Connection timed out');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('Connection refused: Server is unreachable');
      }
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders())
          .timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } on SocketException {
      throw Exception('Connection refused: Server is unreachable');
    } on TimeoutException {
      throw Exception('Connection timed out');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('Connection refused: Server is unreachable');
      }
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
    } 
    
    // Handle Unauthorized
    if (response.statusCode == 401) {
      _sessionController.clearSession();
      Get.offAllNamed('/login');
      throw ApiException('Unauthorized session. Please login again.', 401);
    }
    
    // Handle Server Errors (500+)
    if (response.statusCode >= 500) {
      String errorMessage = 'Internal Server Error';
      try {
        final body = json.decode(response.body);
        if (body['message'] != null) {
          errorMessage = body['message'];
        }
      } catch (_) {
         // Fallback to status text
      }
      throw ApiException(errorMessage, response.statusCode, response.body);
    }

    // Handle Client Errors (400-499)
    String errorMessage = 'Request Failed: ${response.statusCode}';
    try {
      final body = json.decode(response.body);
      if (body['message'] != null) {
        errorMessage = body['message'];
      } else if (body['error'] != null && body['error'] is String) {
        errorMessage = body['error'];
      }
    } catch (_) {
      if (response.body.isNotEmpty) {
         errorMessage = response.body.length > 100 
             ? response.body.substring(0, 100) 
             : response.body;
      }
    }
    
    throw ApiException(errorMessage, response.statusCode, response.body);
  }
}
