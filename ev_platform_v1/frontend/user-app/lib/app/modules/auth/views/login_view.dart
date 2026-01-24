import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/app/modules/auth/controllers/auth_controller.dart';
import 'package:user_app/app/routes/app_routes.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

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
              child: Column(
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
                      "Welcome Back",
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
                      "Sign in to manage your EV charging",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: onSurface.withOpacity(0.7),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Tabs
                  DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: theme.inputDecorationTheme.fillColor ??
                                (isDark
                                    ? const Color(0xFF2B2B2B)
                                    : const Color(0xFFF5F5F5)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: isDark ? Colors.white : Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelColor: isDark ? Colors.black : Colors.white,
                            unselectedLabelColor: onSurface.withOpacity(0.5),
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
                          height: 400,
                          child: TabBarView(
                            children: [
                              _buildPasswordLogin(context, isDark),
                              _buildOtpLogin(context, isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Register Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: onSurface.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Get.toNamed(Routes.REGISTER),
                          child: Text(
                            "Create Account",
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
              ),
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

  Widget _buildPasswordLogin(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextField(
            context,
            controller: controller.emailController,
            hint: "Email Address",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            context,
            controller: controller.passwordController,
            hint: "Password",
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {}, // TODO: Forgot Password
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.loginWithPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Sign In",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpLogin(BuildContext context, bool isDark) {
    return Obx(() {
      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!controller.isOtpSent.value) ...[
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
                      : () => controller.sendOtp(forRegistration: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Send Verification Code",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ] else ...[
              _buildTextField(
                context,
                controller: controller.emailController,
                hint: "Email Address",
                icon: Icons.email_outlined,
                enabled: false,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                context,
                controller: controller.otpController,
                hint: "Enter 6-digit code",
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              "Verify & Sign In",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      controller.isOtpSent.value = false;
                    },
                    icon: Icon(Icons.arrow_back, size: 16, color: Theme.of(context).colorScheme.onSurface),
                    label: Text(
                      'Change Email',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      );
    });
  }
}

