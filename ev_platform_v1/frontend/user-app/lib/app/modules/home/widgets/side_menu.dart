import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/app/modules/trip/views/saved_trips_view.dart';
import 'package:user_app/app/modules/about/views/about_view.dart';
import 'package:user_app/app/modules/support/controllers/support_controller.dart';
import 'package:user_app/app/modules/reservation/views/reservation_view.dart';
import 'package:user_app/app/modules/profile/controllers/profile_controller.dart';
import 'package:user_app/app/modules/wallet/controllers/wallet_controller.dart';
import 'package:user_app/app/modules/session_history/controllers/session_history_controller.dart';
import 'package:user_app/app/modules/reservation/controllers/reservation_controller.dart';
import 'package:user_app/app/routes/app_routes.dart';
import 'package:user_app/core/theme/app_colors.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is available
    final controller = Get.put(ProfileController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Container(
        margin: const EdgeInsets.only(top: 50, bottom: 100, left: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? theme.cardColor.withOpacity(0.9)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(10, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Section (Enhanced)
                  Obx(() {
                    final user = controller.user.value;
                    return Container(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                        border: Border(
                          bottom: BorderSide(
                            color: theme.dividerColor.withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                            Get.delete<ProfileController>();
                            Get.toNamed(Routes.PROFILE);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    user?.username?.isNotEmpty == true 
                                        ? user!.username![0].toUpperCase() 
                                        : 'G',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: theme.dividerColor, width: 2),
                                    ),
                                    child: Icon(
                                      Icons.edit_rounded,
                                      size: 12,
                                      color: theme.iconTheme.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.username ?? 'Guest User',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.titleLarge?.color,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'View Profile',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 8,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
        
                  // Menu Items (Grouped in Cards)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(context, 'MENU'),
                          const SizedBox(height: 12),
                          _buildMenuCard(context, [
                            _buildMenuItem(
                              context,
                              icon: Icons.history_rounded,
                              title: 'Charging History',
                              onTap: () {
                                if (Get.isRegistered<SessionHistoryController>()) {
                                    Get.find<SessionHistoryController>().fetchSessions();
                                }
                                Get.toNamed(Routes.CHARGING_SESSIONS);
                              },
                            ),
                            _buildDivider(context),
                            _buildMenuItem(
                              context,
                              icon: Icons.receipt_long_rounded,
                              title: 'Transactions',
                              onTap: () {
                                Get.delete<WalletController>();
                                Get.toNamed(Routes.WALLET);
                              },
                            ),
                            _buildDivider(context),
                            _buildMenuItem(
                              context,
                              icon: Icons.directions_car_filled_rounded,
                              title: 'My Vehicles',
                              onTap: () {
                                Get.toNamed(Routes.MY_VEHICLES);
                              },
                            ),
                          ]),
        
                          const SizedBox(height: 24),
                          _buildSectionTitle(context, 'SERVICES'),
                          const SizedBox(height: 12),
                          _buildMenuCard(context, [
                            Obx(
                              () => _buildMenuItem(
                                context,
                                icon: Icons.calendar_today_rounded,
                                title: 'Reservations',
                                onTap: () {
                                    Get.delete<ReservationController>();
                                    Get.toNamed(Routes.RESERVATIONS) ??
                                    Get.to(() => const ReservationView());
                                },
                                badgeText: controller.upcomingReservationText.value,
                              ),
                            ),
                            _buildDivider(context),
                            _buildMenuItem(
                              context,
                              icon: Icons.bookmark_rounded,
                              title: 'Saved trips',
                              onTap: () => Get.toNamed(Routes.SAVED_TRIPS),
                            ),
                          ]),
        
                          const SizedBox(height: 24),
                          _buildSectionTitle(context, 'GENERAL'),
                          const SizedBox(height: 12),
                          _buildMenuCard(context, [
                            _buildMenuItem(
                              context,
                              icon: Icons.support_agent_rounded,
                              title: 'Support',
                              onTap: () {
                                  Get.delete<SupportController>();
                                  Get.toNamed(Routes.SUPPORT);
                              },
                            ),
                            _buildDivider(context),
                            _buildMenuItem(
                              context,
                              icon: Icons.info_outline_rounded,
                              title: 'About',
                              onTap: () => Get.to(() => const AboutView()),
                            ),
                          ]),
        
                          const SizedBox(height: 24),
                          _buildMenuCard(context, [
                            _buildMenuItem(
                              context,
                              icon: Icons.logout_rounded,
                              title: 'Logout',
                              onTap: controller.logout,
                              isDestructive: true,
                            ),
                          ], isDestructive: true),
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        title,
        style: GoogleFonts.orbitron(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).disabledColor,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, List<Widget> children, {bool isDestructive = false}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isDestructive 
            ? AppColors.error.withOpacity(0.05) 
            : theme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDestructive 
              ? AppColors.error.withOpacity(0.1) 
              : theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 16,
      color: Theme.of(context).dividerColor.withOpacity(0.1),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? badgeText,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive ? AppColors.error : theme.textTheme.bodyLarge?.color;
    final iconColor = isDestructive ? AppColors.error : AppColors.primary;
    final bgColor = isDestructive ? Colors.white : AppColors.primary.withOpacity(0.08);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              if (badgeText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ] else if (!isDestructive)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: theme.disabledColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
