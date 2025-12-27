import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/feature/auth/presentation/controllers/auth_controller.dart';
import 'package:user_app/routes/app_routes.dart';
import 'package:user_app/utils/theme/themes.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // Reset state when entering screen
    controller.resetState();

    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450), // Responsive Max Width
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & Header
                Icon(
                  Icons.electric_bolt_rounded, 
                  size: 64, 
                  color: AppTheme.primaryColor
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to manage your EV charging',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),

                // Login Form Card
                Card(
                  elevation: 0,
                  color: Colors.transparent, // Or white if background is grey
                  child: Column(
                    children: [
                      // Custom Tab Switcher could be better, but sticking to TabBar for now
                      DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TabBar(
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicator: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                labelColor: AppTheme.primaryColor,
                                unselectedLabelColor: Colors.grey[600],
                                dividerColor: Colors.transparent,
                                padding: const EdgeInsets.all(4),
                                tabs: const [
                                  Tab(text: 'Password'),
                                  Tab(text: 'OTP'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 350, 
                              child: TabBarView(
                                children: [_buildPasswordLogin(), _buildOtpLogin()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account?',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => Get.toNamed(Routes.REGISTER),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordLogin() {
    return Column(
      children: [
        TextField(
          controller: controller.emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
            hintText: 'Enter your email',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller.passwordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
            hintText: 'Enter your password',
          ),
          obscureText: true,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {}, // TODO: Forgot Password
            child: const Text('Forgot Password?'),
          ),
        ),
        const SizedBox(height: 24),
        Obx(
          () => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.loginWithPassword,
                    child: const Text('Sign In'),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOtpLogin() {
    return Obx(() {
      if (!controller.isOtpSent.value) {
        // Step 1: Send OTP
        return Column(
          children: [
            TextField(
              controller: controller.emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
                hintText: 'Enter your email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () =>
                          controller.sendOtp(forRegistration: false),
                      child: const Text('Send Verification Code'),
                    ),
                  ),
          ],
        );
      } else {
        // Step 2: Verify OTP
        return Column(
          children: [
            TextField(
              controller: controller.emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              enabled: false, 
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller.otpController,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                prefixIcon: Icon(Icons.pin_outlined),
                hintText: 'Enter 6-digit code',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: controller.verifyOtp,
                          child: const Text('Verify & Sign In'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          controller.isOtpSent.value = false;
                        },
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Change Email'),
                      ),
                    ],
                  ),
          ],
        );
      }
    });
  }
}

