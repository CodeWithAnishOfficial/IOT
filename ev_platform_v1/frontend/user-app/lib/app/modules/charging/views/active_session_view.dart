import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/app/modules/charging/controllers/charging_controller.dart';
import 'package:user_app/app/modules/home/widgets/swipe_button.dart';
import 'package:user_app/core/theme/app_theme.dart';
import 'package:user_app/core/theme/app_colors.dart';

class ChargingView extends StatelessWidget {
  final String connectorId;
  final double initialAmount;
  final String sessionId;

  const ChargingView({
    super.key,
    required this.connectorId,
    required this.initialAmount,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChargingController(
      connectorId: connectorId,
      initialAmount: initialAmount,
      sessionId: sessionId,
    ));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
          children: [
            // Background Image
            if (isDark)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/ChargingPage_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
            
            // 1. Top Header
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                          child: IconButton(
                            icon: Icon(Icons.keyboard_arrow_down, color: theme.iconTheme.color),
                            onPressed: () => Get.back(), // Minimize/Back
                          ),
                        ),
                        Text(
                          "Charge",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(width: 40), // Balance
                      ],
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                      controller.durationString.value,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 16,
                        color: theme.textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    )),
                  ],
                ),
              ),
            ),

            // 3. Stats & Action Overlay (Bottom Sheet)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1F2B), // Dark Navy
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress Circle
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Obx(() {
                          double progress = 0.0;
                          if (controller.initialAmount > 0) {
                            progress = controller.currentCost.value / controller.initialAmount;
                            if (progress > 1.0) progress = 1.0;
                          }
                          return SizedBox(
                            width: 180,
                            height: 180,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 12,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                              strokeCap: StrokeCap.round,
                            ),
                          );
                        }),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             Obx(() => Text(
                                "${controller.energyDelivered.value.toStringAsFixed(2)}",
                                style: GoogleFonts.poppins(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                             )),
                             Text(
                                "kWh",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                             ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem("Rate", "₹${controller.ratePerKwh}/kWh"),
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                        Obx(() => _buildStatItem("Cost", "₹${controller.currentCost.value.toStringAsFixed(2)}")),
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                        _buildStatItem("Connector", "CCS2"),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Swipe to Stop
                    SizedBox(
                      width: double.infinity,
                      child: SwipeButton(
                        onSwipe: controller.stopCharging,
                        text: "Swipe to Stop",
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        icon: Icons.stop_rounded,
                        height: 60,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

