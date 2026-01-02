import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/feature/home/presentation/controllers/home_controller.dart';
import 'package:user_app/feature/home/presentation/widgets/start_charging_sheet.dart';

class ChargingPreparationView extends StatelessWidget {
  final String connectorId;
  final HomeController homeController;

  const ChargingPreparationView({
    super.key,
    required this.connectorId,
    required this.homeController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
          children: [
            // Background Image
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
                          backgroundColor: Colors.white.withOpacity(0.1),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Get.back(),
                          ),
                        ),
                        Text(
                          "Start Session",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 40), // Balance
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 3. Stats & Action Overlay (Bottom Half)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.9),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
            
            Positioned(
              bottom: 40 + MediaQuery.of(context).padding.bottom,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    height: 320,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // The Grid Lines
                        Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: Container()), // Top Left
                                  Container(width: 1, color: Colors.white.withOpacity(0.1)),
                                  Expanded(child: Container()), // Top Right
                                ],
                              ),
                            ),
                            Container(height: 1, color: Colors.white.withOpacity(0.1)),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: Container()), // Bottom Left
                                  Container(width: 1, color: Colors.white.withOpacity(0.1)),
                                  Expanded(child: Container()), // Bottom Right
                                ],
                              ),
                            ),
                          ],
                        ),

                        // The Content
                        Column(
                          children: [
                            // Top Row
                            Expanded(
                              child: Row(
                                children: [
                                  // Top Left: Connector
                                  Expanded(
                                    child: _buildStatTile(
                                      icon: Icons.electrical_services,
                                      value: connectorId,
                                      label: "Connector",
                                      alignLeft: true,
                                    ),
                                  ),
                                  // Top Right: Charged
                                  Expanded(
                                    child: _buildStatTile(
                                      icon: Icons.battery_charging_full,
                                      value: "0.00 kW",
                                      label: "Charged",
                                      alignLeft: false,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Bottom Row
                            Expanded(
                              child: Row(
                                children: [
                                  // Bottom Left: Rate
                                  Expanded(
                                    child: _buildStatTile(
                                      icon: Icons.price_change,
                                      value: "0.7\$/kWh",
                                      label: "Rate",
                                      alignLeft: true,
                                    ),
                                  ),
                                  // Bottom Right: Cost
                                  Expanded(
                                    child: _buildStatTile(
                                      icon: Icons.attach_money,
                                      value: "0.00\$",
                                      label: "Cost",
                                      alignLeft: false,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // The Center Button
                        GestureDetector(
                          onTap: () {
                             Get.bottomSheet(
                              StartChargingSheet(
                                controller: homeController, 
                                connectorId: connectorId
                              ),
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                            );
                          },
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFCCFF00), // Neon Lime
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFCCFF00).withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "START",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
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

  Widget _buildStatTile({
    required IconData icon,
    required String value,
    required String label,
    required bool alignLeft,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFCCFF00).withOpacity(0.2), // Faint Lime
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFCCFF00), size: 20),
          ),
          const SizedBox(height: 12),
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
      ),
    );
  }
}
