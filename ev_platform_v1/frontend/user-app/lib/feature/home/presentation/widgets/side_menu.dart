import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/feature/home/presentation/pages/saved_trips_view.dart';
import 'package:user_app/feature/more/presentation/pages/about/presentation/pages/about_view.dart';
import 'package:user_app/feature/more/presentation/pages/help&support/presentation/controllers/support_controller.dart';
import 'package:user_app/feature/reservation/presentation/pages/reservation_view.dart';
import 'package:user_app/feature/more/presentation/pages/account/presentation/controllers/profile_controller.dart';
import 'package:user_app/feature/wallet/presentation/controllers/wallet_controller.dart';
import 'package:user_app/feature/session_history/presentation/controllers/session_history_controller.dart';
import 'package:user_app/feature/reservation/presentation/controllers/reservation_controller.dart';
import 'package:user_app/routes/app_routes.dart';

import 'package:user_app/utils/theme/themes.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is available
    final controller = Get.put(ProfileController());

    return Drawer(
      backgroundColor: Colors.black, // Solid Black
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(0),
        ), // Square edges like screenshot
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black, // Solid Black
        ),
        child: Column(
          children: [
            // Header
            Obx(() {
              final user = controller.user.value;
              return InkWell(
                onTap: () {
                    Get.delete<ProfileController>();
                    Get.toNamed(Routes.PROFILE);
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
                  color: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white12,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user?.username ?? 'Guest User',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // 1. Session History
                  _buildMenuItem(
                    icon: Icons.history, // Or restore_rounded
                    title: 'Charging History',
                    onTap: () {
                      // Ensure fresh data is loaded
                      if (Get.isRegistered<SessionHistoryController>()) {
                          Get.find<SessionHistoryController>().fetchSessions();
                      } else {
                          // Will be created and fetch on init
                      }
                      Get.toNamed(Routes.CHARGING_SESSIONS);
                    },
                  ),
                  
                  // 2. Transaction History
                  _buildMenuItem(
                    icon: Icons.receipt_long_outlined, // Better icon for transactions
                    title: 'Transaction History',
                    onTap: () {
                      Get.delete<WalletController>();
                      Get.toNamed(Routes.WALLET);
                    },
                  ),

                  // 3. Reserved Stations
                  Obx(
                    () => _buildMenuItem(
                      icon: Icons.calendar_today_outlined,
                      title: 'Reserved Stations',
                      onTap: () {
                          Get.delete<ReservationController>();
                          Get.toNamed(Routes.RESERVATIONS) ??
                          Get.to(() => const ReservationView());
                      },
                      badgeText: controller
                          .upcomingReservationText
                          .value, // Dynamic text
                    ),
                  ),

                  // 4. Saved Trips
                  _buildMenuItem(
                    icon: Icons.bookmark_outline,
                    title: 'Saved trips',
                    onTap: () => Get.to(() => const SavedTripsView()),
                  ),

                  // 5. Support
                  _buildMenuItem(
                    icon: Icons.support_agent_outlined,
                    title: 'Support',
                    onTap: () {
                        Get.delete<SupportController>();
                        Get.toNamed(Routes.SUPPORT);
                    },
                  ),

                  // 6. About
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () => Get.to(() => const AboutView()),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Divider(color: Colors.white12),
                  ),
                  
                  // 7. Logout (Red)
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: controller.logout,
                    isDestructive: true, // Custom flag for red color
                  ),
                ],
              ),
            ),

            // Footer Version
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Version 1.0.0",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? badgeText,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : Colors.white;
    final iconColor = isDestructive ? Colors.red : Colors.white70;
    
    return ListTile(
      leading: SizedBox(
        width: 24,
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: color,
            ),
          ),
          if (badgeText != null) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      horizontalTitleGap: 24,
    );
  }
}
