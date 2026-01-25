import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/app/modules/charging/controllers/charging_controller.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/app/modules/charging/views/active_session_view.dart';

class ActiveSessionCard extends StatefulWidget {
  final ChargingController controller;

  const ActiveSessionCard({
    super.key,
    required this.controller,
  });

  @override
  State<ActiveSessionCard> createState() => _ActiveSessionCardState();
}

class _ActiveSessionCardState extends State<ActiveSessionCard> {
  bool _isExpanded = false;

  void _navigateToDetails() {
    Get.to(
      () => ChargingView(
        controller: widget.controller,
      ),
      transition: Transition.downToUp,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _confirmStop() {
    Get.defaultDialog(
      title: "Stop Charging",
      middleText: "Are you sure you want to stop?",
      textConfirm: "Stop",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      onConfirm: () {
        Get.back();
        widget.controller.stopCharging();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => setState(() => _isExpanded = true),
      onLongPressEnd: (_) => setState(() => _isExpanded = false),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40), // More rounded like dynamic island
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            width: double.infinity,
            height: _isExpanded ? 180 : 80, // Height expansion
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF000000).withOpacity(0.85), // Deep black/glass
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isExpanded 
                 ? KeyedSubtree(
                     key: const ValueKey("expanded"),
                     child: _buildExpandedView()
                   )
                 : KeyedSubtree(
                     key: const ValueKey("collapsed"),
                     child: _buildCollapsedView()
                   ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Open Button (Green Circle)
        GestureDetector(
          onTap: _navigateToDetails,
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 24),
          ),
        ),

        // Center Info
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Active Session",
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Obx(() => Text(
                "${widget.controller.soc.value.toInt()}% • ${widget.controller.durationString.value}",
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              )),
            ],
          ),
        ),

        // Stop Button (Red Circle)
        GestureDetector(
          onTap: _confirmStop,
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.stop_rounded, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedView() {
    // Battery Visual Design for Peek State
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt, color: AppColors.success, size: 24),
            const SizedBox(width: 8),
            Text(
              "Charging",
              style: GoogleFonts.poppins(
                color: AppColors.success,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Big Percentage
        Obx(() => Text(
          "${widget.controller.soc.value.toInt()}%",
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        )),
        
        const SizedBox(height: 12),
        
        // Progress Bar
        Obx(() => SizedBox(
          width: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.controller.soc.value / 100,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
              minHeight: 6,
            ),
          ),
        )),
        
        const SizedBox(height: 8),
        Obx(() => Text(
          "${widget.controller.currentPower.value.toStringAsFixed(1)} kW • ${widget.controller.energyDelivered.value.toStringAsFixed(1)} kWh",
          style: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 12,
          ),
        )),
      ],
    );
  }
}
