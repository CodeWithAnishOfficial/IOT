import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:user_app/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:user_app/app/modules/home/views/home_view.dart';
import 'package:user_app/app/modules/home/views/search_location_view.dart';
import 'package:user_app/app/modules/reservation/views/reservation_view.dart';
import 'package:user_app/app/modules/news/views/news_view.dart';
import 'package:user_app/core/theme/app_colors.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Content Pages
          PageView(
            controller: controller.pageController,
            physics:
                const NeverScrollableScrollPhysics(), // Disable swipe for now to avoid conflict with map
            children: const [
              HomeView(),
              SearchLocationView(isEmbedded: true), // Trip Page
              ReservationView(),
              NewsView(),
            ],
          ),

          // Custom Floating Navigation Bar
          Obx(
            () => AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: 0,
              right: 0,
              bottom: controller.isNavBarVisible.value ? 0 : -100,
              child: _buildFloatingNavBar(isDark, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      height: 64,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? theme.cardColor.withOpacity(0.8)
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Obx(() {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      0,
                      Iconsax.map_1,
                      Iconsax.map5,
                      isDark,
                      theme,
                    ),
                    _buildNavItem(
                      1,
                      Iconsax.routing,
                      Iconsax.routing5,
                      isDark,
                      theme,
                    ), // or routing_2
                    _buildNavItem(
                      2,
                      Iconsax.calendar_1,
                      Iconsax.calendar5,
                      isDark,
                      theme,
                    ),
                    _buildNavItem(
                      3,
                      Iconsax.global,
                      Iconsax.global,
                      isDark,
                      theme,
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    bool isDark,
    ThemeData theme,
  ) {
    final isSelected = controller.tabIndex.value == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        controller.changeTabIndex(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? theme.colorScheme.onSurface.withOpacity(0.15)
                    : Colors.black.withOpacity(0.08))
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withOpacity(0.4),
          size: 24,
        ),
      ),
    );
  }
}
