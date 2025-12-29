import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/feature/charging/presentation/controllers/charging_controller.dart';
import 'package:user_app/utils/theme/themes.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFF111111), // Deep black/grey background
      body: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                "assets/images/ChargingPage_bg.png",
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
                          backgroundColor: Colors.white.withOpacity(0.1),
                          child: IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                            onPressed: () => Get.back(), // Minimize/Back
                          ),
                        ),
                        Text(
                          "Charge",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    )),
                  ],
                ),
              ),
            ),

            // 2. Car Image (Centered)
            Positioned.fill(
              top: 80 + MediaQuery.of(context).padding.top,
              bottom: 250, // Leave space for bottom panel
              child: Center(
                child: Image.network(
                  "https://png.pngtree.com/png-vector/20240130/ourmid/pngtree-top-view-of-white-sports-car-isolated-on-transparent-background-png-image_11571404.png",
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Icon(Icons.directions_car, size: 100, color: Colors.grey[800]),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.electric_car, 
                    size: 150, 
                    color: Colors.grey[800]
                  ),
                ),
              ),
            ),

            // 3. Stats & Action Overlay (Bottom Half)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 380,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
            
            Positioned(
              bottom: 30 + MediaQuery.of(context).padding.bottom,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Stats Grid
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Connector
                            _buildStatItem(
                              icon: Icons.electrical_services,
                              label: "Connector",
                              value: "CCS2",
                              color: const Color(0xFFD4E157), // Lime Greenish
                            ),
                            // Energy/Power
                            Obx(() => _buildStatItem(
                              icon: Icons.flash_on,
                              label: "Charged",
                              value: "${controller.energyDelivered.value.toStringAsFixed(2)} kWh",
                              color: Colors.white,
                            )),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Center Action Button
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background Elements (Grid lines)
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            Container(
                              height: 100,
                              width: 1,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            
                            // The Button
                            GestureDetector(
                              onTap: controller.stopCharging,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFCCFF00), // Neon Lime
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFCCFF00).withOpacity(0.4),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Obx(() => Text(
                                    controller.status.value == "Completed" ? "DONE" : "STOP",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      letterSpacing: 1,
                                    ),
                                  )),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Bottom Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Rate
                            _buildStatItem(
                              icon: Icons.price_change_outlined,
                              label: "Rate",
                              value: "\$${controller.ratePerKwh}/kWh",
                              color: Colors.white70,
                            ),
                            // Cost
                            Obx(() => _buildStatItem(
                              icon: Icons.attach_money,
                              label: "Cost",
                              value: "\$${controller.currentCost.value.toStringAsFixed(2)}",
                              color: Colors.white,
                              alignRight: true,
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}
