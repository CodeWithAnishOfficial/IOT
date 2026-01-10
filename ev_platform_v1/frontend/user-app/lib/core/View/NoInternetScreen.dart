import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/core/controllers/connectivity_controller.dart';
import 'package:user_app/utils/theme/themes.dart';
import 'package:user_app/utils/widgets/snackbar/custom_snackbar.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityController = Get.find<ConnectivityController>();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    // Check if we are in dark mode to adjust card color if needed, 
    // though AppTheme seems to force dark mode.
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async => false, // Disable back navigation
      child: Scaffold(
        // Use transparent background to show the global background image/color
        backgroundColor: Colors.transparent,
        body: Obx(() {
          if (connectivityController.isConnected.value) {
             // Navigate back when internet is restored.
             // Using a slight delay to ensure the UI has time to react/animate if needed
             // but mostly to avoid build phase errors.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Get.currentRoute == '/noInternet') {
                 Get.back();
              }
            });
          }

          return Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                // Use the card theme color or a specific surface color
                // White card on dark background was requested, but "in our apptheme".
                // Our apptheme is dark. A bright white card might glare.
                // I'll use the Card Theme surface which is glassmorphic/dark.
                // If the user REALLY wants white, they would usually explicitly say "white card".
                // Given "ui neeed thz same dgein sample in our apptheme", I'll stick to the app's card style.
                color: theme.cardTheme.color ?? const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Illustration
                  _buildIllustration(theme),
                  
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    "Oops",
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Subtitle
                  Text(
                    "There is a connection error",
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                   const SizedBox(height: 8),
                  Text(
                    "Please check your internet connection and try again.",
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Retry Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.black, // Text color
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        // Show loading or visual feedback? 
                        // The controller updates the observable, which triggers the check.
                        await connectivityController.checkConnection();
                        if (!connectivityController.isConnected.value) {
                          _showNoInternetSnackbar();
                        }
                      },
                      child: const Text(
                        "Retry",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildIllustration(ThemeData theme) {
    return SizedBox(
      height: 120,
      width: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle (faint)
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          
          // Globe Icon
          Positioned(
            top: 10,
            child: Icon(
              Icons.public,
              size: 50,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          
          // Dashed Line (Simulated with dots)
          Positioned(
             top: 65,
             child: Column(
               children: [
                 _dot(),
                 const SizedBox(height: 4),
                 _dot(),
                 const SizedBox(height: 4),
                 _dot(),
               ],
             ),
          ),

          // Phone Icon
          Positioned(
            bottom: 10,
            child: Icon(
              Icons.smartphone,
              size: 40,
              color: theme.primaryColor, // Use brand color for the device
            ),
          ),
          
           // Warning/Error Indicator
          Positioned(
            right: 25,
            bottom: 45,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error,
                size: 20,
                color: Color(0xFFE76767), // Error color
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _dot() {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }

  void _showNoInternetSnackbar() {
    CustomSnackbar.showError(
      message: "Still no internet connection. Please check your settings.",
    );
  }
}
