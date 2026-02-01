import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
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
  // Use 64.227.181.90 for Android emulator, 64.227.181.90 for iOS simulator
  static String get baseUrl {
    if (GetPlatform.isAndroid) {
      // Android Emulator maps 64.227.181.90 to host 64.227.181.90
      return 'http://64.227.181.90:3000';
    }
    // iOS Simulator / Web uses 64.227.181.90 (or Cloud IP)
    return 'http://64.227.181.90:3000';
  }

  final SessionController _sessionController = Get.find<SessionController>();

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders())
          .timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } on SocketException catch (_) {
      throw ApiException(
        'Unable to connect to server. Please check your internet.',
        503,
      );
    } on TimeoutException catch (_) {
      throw ApiException('Server is taking too long to respond.', 408);
    } catch (e) {
      debugPrint('ApiProvider Error: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw ApiException(
          'Unable to connect to server. Please check your internet.',
          503,
        );
      }
      throw ApiException('Something went wrong. Please try again.', 500);
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
    } on SocketException catch (_) {
      throw ApiException(
        'Unable to connect to server. Please check your internet.',
        503,
      );
    } on TimeoutException catch (_) {
      throw ApiException('Server is taking too long to respond.', 408);
    } catch (e) {
      debugPrint('ApiProvider Error: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw ApiException(
          'Unable to connect to server. Please check your internet.',
          503,
        );
      }
      throw ApiException('Something went wrong. Please try again.', 500);
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
      String errorMessage = 'Something went wrong on our end.';
      try {
        final body = json.decode(response.body);
        if (body['message'] != null) {
          // If the server sends a specific message, it might be technical.
          // But usually we trust our own server messages.
          // If the user wants "user friendly", we might mask it unless it's a known business error.
          // For now, I'll keep the server message but fallback to friendly.
          errorMessage = body['message'];
        }
      } catch (_) {
        // Fallback
      }
      throw ApiException(errorMessage, response.statusCode, response.body);
    }

    // Handle Client Errors (400-499)
    String errorMessage = 'Request Failed';
    try {
      final body = json.decode(response.body);
      if (body['message'] != null) {
        errorMessage = body['message'];
      } else if (body['error'] != null && body['error'] is String) {
        errorMessage = body['error'];
      }
    } catch (_) {
      debugPrint(
        'ApiProvider: Failed to decode error response (Status ${response.statusCode}). Body: ${response.body}',
      );
      if (response.body.isNotEmpty) {
        // If it's a 404 and not JSON, it's likely a wrong route
        if (response.statusCode == 404) {
          errorMessage = '404: Endpoint not found';
        } else {
          errorMessage =
              'An unexpected error occurred (Status ${response.statusCode})';
        }
      }
    }

    throw ApiException(errorMessage, response.statusCode, response.body);
  }
}
