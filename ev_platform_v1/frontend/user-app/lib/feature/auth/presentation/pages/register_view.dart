import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/feature/auth/presentation/controllers/auth_controller.dart';

class RegisterView extends GetView<AuthController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    // Reset state when entering screen
    controller.resetState();

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          // Step 1: Email Input
          if (!controller.isOtpSent.value) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add, size: 80, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  'Create an Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                TextField(
                  controller: controller.emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    helperText: 'We will send you an OTP to verify',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),

                controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              controller.sendOtp(forRegistration: true),
                          child: const Text('Send OTP'),
                        ),
                      ),
              ],
            );
          }
          // Step 2: Details + OTP
          else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  const Text(
                    'Complete Registration',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: controller.emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    enabled: false,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: controller.otpController,
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP',
                      prefixIcon: Icon(Icons.pin),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: controller.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: controller.phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (Optional)',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: controller.passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Set Password (Optional)',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),

                  controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: controller.verifyOtp,
                                child: const Text('Register'),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                controller.isOtpSent.value = false;
                              },
                              child: const Text('Change Email'),
                            ),
                          ],
                        ),
                ],
              ),
            );
          }
        }),
      ),
    );
  }
}
