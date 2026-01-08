import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/feature/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:user_app/feature/home/presentation/pages/home_view.dart';
import 'package:user_app/feature/home/presentation/pages/search_location_view.dart';
import 'package:user_app/feature/reservation/presentation/pages/reservation_view.dart';
import 'package:user_app/feature/news/presentation/pages/news_view.dart';
import 'package:user_app/utils/theme/themes.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Ensure dark background
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Content Pages
          Obx(() => IndexedStack(
            index: controller.tabIndex.value,
            children: const [
              HomeView(),
              SearchLocationView(isEmbedded: true), // Trip Page
              ReservationView(),
              NewsView(),
            ],
          )),

          // 2. Custom Floating Navigation Bar
          Positioned(
            left: 24,
            right: 24,
            bottom: 34,
            child: _buildFloatingNavBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.95), // Highly saturated fluorescent BG
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3), // Darker shadow for better contrast on dark map
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home_filled), // Home
              _buildNavItem(1, Icons.directions), // Trips
              _buildNavItem(2, Icons.calendar_month_outlined), // Reservations
              _buildNavItem(3, Icons.newspaper), // News
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    return Obx(() {
      final isSelected = controller.tabIndex.value == index;
      return GestureDetector(
        onTap: () => controller.changeTabIndex(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 60, // Increased width for bigger touch target
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top Indicator Line
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: 24, // Wider line
                  height: 4, // Thicker line
                  decoration: BoxDecoration(
                    color: Colors.black, // Black Line
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                const SizedBox(height: 12), // Adjusted margin
                
              Icon(
                icon,
                color: isSelected ? Colors.black : Colors.black54, // Black Icons
                size: 32, // Bigger icon size (was 26)
                weight: 700, // Attempt to make it bolder (works with MaterialSymbols if available, otherwise just larger size helps)
              ),
              
              const SizedBox(height: 12), // Balance vertical space
            ],
          ),
        ),
      );
    });
  }
}
