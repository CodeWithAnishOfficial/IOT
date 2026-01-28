import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/app/modules/trip/views/saved_trips_view.dart';
import 'package:user_app/app/modules/news/views/news_view.dart';
import 'package:user_app/app/modules/about/views/about_view.dart';
import 'package:user_app/app/modules/support/controllers/support_controller.dart';
import 'package:user_app/app/modules/reservation/views/reservation_view.dart';
import 'package:user_app/app/modules/profile/controllers/profile_controller.dart';
import 'package:user_app/app/modules/wallet/controllers/wallet_controller.dart';
import 'package:user_app/app/modules/session_history/controllers/session_history_controller.dart';
import 'package:user_app/app/modules/reservation/controllers/reservation_controller.dart';
import 'package:user_app/app/routes/app_routes.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/controllers/session_controller.dart';

class DrawerView extends StatelessWidget {
  const DrawerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());
    final sessionController = Get.find<SessionController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Close Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Text(
                    'Menu',
                    style: GoogleFonts.orbitron(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Profile Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Obx(() {
                final username = sessionController.username.value;
                return InkWell(
                  onTap: () {
                      Get.delete<ProfileController>();
                      Get.toNamed(Routes.PROFILE);
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
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
                            username.isNotEmpty == true 
                                ? username[0].toUpperCase() 
                                : 'G',
                            style: GoogleFonts.orbitron(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username.isNotEmpty ? username : 'Guest User',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.titleLarge?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'View Profile',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: theme.disabledColor,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Menu Items
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'MAIN'),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      icon: Icons.receipt_long_rounded,
                      title: 'Transactions',
                      onTap: () {
                        Get.delete<WalletController>();
                        Get.toNamed(Routes.WALLET);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      icon: Icons.directions_car_filled_rounded,
                      title: 'My Vehicles',
                      onTap: () {
                        Get.toNamed(Routes.MY_VEHICLES);
                      },
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'SERVICES'),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      icon: Icons.ev_station_rounded,
                      title: 'Commercialization',
                      onTap: () => Get.toNamed(Routes.COMMERCIALIZATION),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      icon: Icons.newspaper_rounded,
                      title: 'Daily News',
                      onTap: () => Get.to(() => const NewsView()),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      icon: Icons.bookmark_rounded,
                      title: 'Saved trips',
                      onTap: () => Get.toNamed(Routes.SAVED_TRIPS),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      icon: Icons.map_rounded,
                      title: 'Trip Planner',
                      onTap: () => Get.toNamed(Routes.TRIP_PLANNER),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'GENERAL'),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      icon: Icons.support_agent_rounded,
                      title: 'Support',
                      onTap: () {
                          Get.delete<SupportController>();
                          Get.toNamed(Routes.SUPPORT);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'About',
                      onTap: () => Get.to(() => const AboutView()),
                    ),

                    const SizedBox(height: 24),
                    _buildMenuItem(
                      context,
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      onTap: controller.logout,
                      isDestructive: true,
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
          letterSpacing: 1.2,
        ),
      ),
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
    final bgColor = isDestructive ? AppColors.error.withOpacity(0.1) : AppColors.primary.withOpacity(0.1);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
                if (badgeText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
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
                    size: 14,
                    color: theme.disabledColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
