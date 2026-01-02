import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/feature/more/presentation/pages/account/presentation/controllers/profile_controller.dart';
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
                onTap: () => Get.toNamed(Routes.PROFILE),
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
                  _buildMenuItem(
                    icon: Icons.electric_bolt_outlined,
                    title: 'Electric',
                    onTap: () => Get.back(), // Close drawer (already on home)
                  ),
                  _buildMenuItem(
                    icon: Icons.history,
                    title: 'History',
                    onTap: () => Get.toNamed(Routes.CHARGING_SESSIONS),
                  ),
                  _buildMenuItem(
                    icon: Icons.eco_outlined,
                    title: 'My Vehicles',
                    onTap: () => Get.toNamed(Routes.MY_VEHICLES),
                  ),
                  _buildMenuItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Wallet',
                    onTap: () => Get.toNamed(Routes.WALLET),
                    badgeText: "VERIFY NOW", // Mimicking "KYC PENDING"
                  ),
                  _buildMenuItem(
                    icon: Icons.payment_outlined,
                    title: 'Payments',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.umbrella_outlined,
                    title: 'Insurance',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.support_agent_outlined, // Lifebuoy icon style
                    title: 'Support',
                    onTap: () => Get.toNamed(Routes.SUPPORT),
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () {},
                  ),

                  // Logout at the bottom of the list or separately? Screenshot doesn't show it but good to have
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Divider(color: Colors.white12),
                  ),
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: controller.logout,
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
  }) {
    return ListTile(
      leading: SizedBox(
        width: 24,
        child: Icon(icon, color: Colors.white70, size: 24),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white,
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
