import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/app/modules/auth/controllers/auth_controller.dart';
import 'package:user_app/app/routes/app_routes.dart';

class RegisterView extends GetView<AuthController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    // Reset state when entering screen
    controller.resetState();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Obx(() {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Logo
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Title
                    Center(
                      child: Text(
                        "Create an Account",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Subtitle
                    Center(
                      child: Text(
                        !controller.isOtpSent.value
                            ? "Enter your email to get started"
                            : "Complete your registration details",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: onSurface.withOpacity(0.7),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    if (!controller.isOtpSent.value) ...[
                      // Step 1: Email Input
                      _buildTextField(
                        context,
                        controller: controller.emailController,
                        hint: "Email Address",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () => controller.sendOtp(forRegistration: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDark ? Colors.white : Colors.black,
                            foregroundColor:
                                isDark ? Colors.black : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  "Send Verification Code",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ] else ...[
                      // Step 2: Details + OTP
                      _buildTextField(
                        context,
                        controller: controller.emailController,
                        hint: "Email Address",
                        icon: Icons.email_outlined,
                        enabled: false,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        context,
                        controller: controller.otpController,
                        hint: "Verification Code",
                        icon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        context,
                        controller: controller.nameController,
                        hint: "Full Name",
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        context,
                        controller: controller.phoneController,
                        hint: "Phone Number (Optional)",
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        context,
                        controller: controller.passwordController,
                        hint: "Set Password (Optional)",
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDark ? Colors.white : Colors.black,
                            foregroundColor:
                                isDark ? Colors.black : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  "Register",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            controller.isOtpSent.value = false;
                          },
                          icon: Icon(Icons.arrow_back,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface),
                          label: Text(
                            'Change Email',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Login Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account?",
                            style: TextStyle(
                              color: onSurface.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Get.offNamed(Routes.LOGIN),
                            child: Text(
                              "Sign In",
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool isPassword = false,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      obscureText: isPassword,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.4)),
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor ??
            (theme.brightness == Brightness.dark
                ? const Color(0xFF2B2B2B)
                : const Color(0xFFF5F5F5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        prefixIcon: icon != null
            ? Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.6))
            : null,
      ),
    );
  }
}
