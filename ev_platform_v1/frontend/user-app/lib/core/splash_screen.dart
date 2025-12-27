import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/core/controllers/session_controller.dart';
import 'package:user_app/feature/auth/presentation/pages/login_view.dart';
import 'package:user_app/feature/home/presentation/pages/home_view.dart';
import 'package:user_app/utils/theme/themes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Don't find the controller immediately - we'll check for it later
  SessionController? _sessionController;
  bool _hasNavigated = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Try to initialize after a short delay to allow GetX to set up
    _initializeWithDelay();
  }

  void _initializeWithDelay() {
    // Delay to allow controllers to be registered
    Future.delayed(const Duration(milliseconds: 1500), () {
      // Increased delay for splash effect
      _tryInitializeController();
    });
  }

  // Counter to limit retry attempts
  int _retryCount = 0;
  static const int _maxRetries = 10;

  void _tryInitializeController() {
    if (_isInitialized) return;

    // Increment retry counter
    _retryCount++;

    try {
      // Try to find the SessionController
      if (Get.isRegistered<SessionController>()) {
        _sessionController = Get.find<SessionController>();
        _setupNavigation();
        _isInitialized = true;
      } else if (_retryCount < _maxRetries) {
        // If not found and we haven't exceeded max retries, try again after a delay
        Future.delayed(
          const Duration(milliseconds: 500),
          _tryInitializeController,
        );
      } else {
        // If we've exceeded max retries, navigate to LoginView as fallback
        debugPrint('Max retries exceeded, navigating to LoginView as fallback');
        _navigateToFallback();
      }
    } catch (e) {
      debugPrint('Error initializing SessionController: $e');
      if (_retryCount < _maxRetries) {
        // Try again after a delay if we haven't exceeded max retries
        Future.delayed(
          const Duration(milliseconds: 500),
          _tryInitializeController,
        );
      } else {
        // Navigate to fallback if max retries exceeded
        _navigateToFallback();
      }
    }
  }

  void _navigateToFallback() {
    if (!_hasNavigated) {
      _hasNavigated = true;
      Get.offAll(
        () => const LoginView(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 800),
      );
    }
  }

  void _setupNavigation() {
    if (_sessionController == null) return;

    // Check login state immediately since we already delayed
    if (_sessionController!.isLoggedIn.value) {
      if (!_hasNavigated) {
        _hasNavigated = true;
        Get.offAll(
          () => const HomeView(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 800),
        );
      }
    } else {
      if (!_hasNavigated) {
        _hasNavigated = true;
        Get.offAll(
          () => const LoginView(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 800),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // MediaQuery for responsiveness
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.elasticOut,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: screenWidth * 0.4,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: screenHeight * 0.02),

            // Animated Text
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Column(
                      children: [
                        Text(
                          "QuanEV",
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.1,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Charging the Future",
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: screenHeight * 0.1),

            // Linear Loading Indicator
            SizedBox(
              width: screenWidth * 0.5,
              child: const LinearProgressIndicator(
                backgroundColor: Color(0xFFE0E0E0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
                minHeight: 4,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
