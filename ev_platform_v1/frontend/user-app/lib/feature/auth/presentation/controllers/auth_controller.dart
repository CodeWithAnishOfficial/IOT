import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/core/network/api_provider.dart';
import 'package:user_app/core/controllers/session_controller.dart';

class AuthController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  SessionController get _sessionController => Get.find<SessionController>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  final isLoading = false.obs;
  final isOtpSent = false.obs;

  // For distinguishing between login and registration flows if needed
  // specific logic, but verify-otp handles both.
  final isRegistering = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.onClose();
  }

  // --- Login with Password ---
  Future<void> loginWithPassword() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill in email and password');
      return;
    }

    try {
      isLoading.value = true;
      final response = await _apiProvider.post('/auth/login', {
        'email_id': emailController.text, // Backend expects email_id
        'password': passwordController.text,
      });

      _handleAuthResponse(response);
    } catch (e) {
      Get.snackbar('Login Failed', _extractErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  // --- OTP Flow (Login or Register) ---

  // Step 1: Send OTP
  Future<void> sendOtp({bool forRegistration = false}) async {
    if (emailController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter your email');
      return;
    }

    // Simple email validation
    if (!GetUtils.isEmail(emailController.text)) {
      Get.snackbar('Error', 'Please enter a valid email');
      return;
    }

    try {
      isLoading.value = true;
      isRegistering.value = forRegistration;

      final endpoint = forRegistration
          ? '/auth/register'
          : '/auth/generate-otp';

      final response = await _apiProvider.post(endpoint, {
        'email_id': emailController.text,
      });

      if (response['error'] == false) {
        isOtpSent.value = true;
        Get.snackbar('Success', response['message'] ?? 'OTP Sent');
      } else {
        Get.snackbar('Error', response['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      Get.snackbar('Error', _extractErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  // Step 2: Verify OTP and Finalize
  Future<void> verifyOtp() async {
    if (otpController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter the OTP');
      return;
    }

    try {
      isLoading.value = true;

      final Map<String, dynamic> body = {
        'email_id': emailController.text,
        'otp': otpController.text,
      };

      // If registering, include additional details
      if (isRegistering.value) {
        if (nameController.text.isNotEmpty)
          body['username'] = nameController.text;
        if (phoneController.text.isNotEmpty)
          body['phone_no'] = phoneController.text;
        if (passwordController.text.isNotEmpty)
          body['password'] = passwordController.text;
      }

      final response = await _apiProvider.post('/auth/verify-otp', body);
      _handleAuthResponse(response);
    } catch (e) {
      Get.snackbar('Verification Failed', _extractErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  void _handleAuthResponse(dynamic response) async {
    if (response['error'] == false && response['token'] != null) {
      final token = response['token'];
      final data = response['data'] ?? {};

      int userId = data['id'] ?? 0; // Ensure your backend sends this
      String email = data['email_id'] ?? emailController.text;
      String username = data['username'] ?? '';

      await _sessionController.saveSession(
        userId: userId,
        emailId: email,
        token: token,
        username: username,
      );

      // Clear forms
      emailController.clear();
      passwordController.clear();
      otpController.clear();
      nameController.clear();
      isOtpSent.value = false;

      Get.offAllNamed('/home');
    } else {
      Get.snackbar('Error', response['message'] ?? 'Authentication failed');
    }
  }

  String _extractErrorMessage(dynamic e) {
    // Try to extract clean message from exception string
    // e.toString() might be "Exception: Error: 400 {"error":true,"message":"User already exists..."}"
    final str = e.toString();
    if (str.contains('"message":"')) {
      final start = str.indexOf('"message":"') + 11;
      final end = str.indexOf('"', start);
      if (end != -1) return str.substring(start, end);
    }
    return str.replaceAll('Exception:', '').trim();
  }

  void resetState() {
    isOtpSent.value = false;
    otpController.clear();
  }
}
