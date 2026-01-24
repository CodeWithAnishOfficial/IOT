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
    // NOTE: We do NOT dispose TextEditingControllers here.
    // In GetX with lazy loading (fenix: true or smart management), the controller instance
    // might be removed from memory (onClose called) but the text controllers
    // could be reused if the user navigates back quickly or if the view holds onto them.
    // Flutter handles text controller disposal automatically if they are part of the state,
    // but in a GetxController, it's safer to let the Garbage Collector handle them
    // rather than manually disposing and risking "used after disposed" errors
    // when the controller is recreated/reattached.
    
    // emailController.dispose();
    // passwordController.dispose();
    // nameController.dispose();
    // phoneController.dispose();
    // otpController.dispose();
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
      Get.snackbar('Login Failed', e.toString());
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
      Get.snackbar('Error', e.toString());
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
      Get.snackbar('Verification Failed', e.toString());
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

      Get.offAllNamed('/home');
      
      // We do not clear fields here to prevent UI glitch before navigation.
      // LoginView calls resetState() on build, which handles necessary resets.
    } else {
      Get.snackbar('Error', response['message'] ?? 'Authentication failed');
    }
  }

  void resetState() {
    isOtpSent.value = false;
    otpController.clear();
  }
}
