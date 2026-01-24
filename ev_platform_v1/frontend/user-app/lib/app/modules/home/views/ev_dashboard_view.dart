import 'package:user_app/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:user_app/app/modules/home/controllers/home_controller.dart';
import 'package:user_app/core/theme/app_colors.dart';

class EvDashboardView extends GetView<HomeController> {
  const EvDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F6F8), // Light grey bg
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              _buildHeader(isDark),

              const SizedBox(height: 20),

              // 2. Car Image
              Center(
                child: SizedBox(
                  height: 200,
                  child: Image.asset(
                    "assets/images/station_detaile_ev_station_img.png", // Using available asset
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 3. Stats Grid
              _buildStatsGrid(isDark),

              const SizedBox(height: 20),

              // 4. Find Closest Stations Card
              _buildMapCard(context, isDark),

              const SizedBox(height: 100), // Bottom padding for nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Good Morning,",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            Text(
              "Ali Husni",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "BMW i8 2015",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Stack(
            children: [
              Icon(
                Iconsax.notification,
                size: 24,
                color: isDark ? Colors.white : Colors.black87,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    return Column(
      children: [
        // Top Row: Battery (Large) + Distance
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Battery Card (Takes more width if possible, but here 1:1 roughly or custom)
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(isDark),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Battery",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                      ],
                    ),
                    Text(
                      "Last charge 2w ago",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Image.asset(
                        // Need a battery icon or draw one. Using simple Column for now.
                        "assets/images/station_detaile_ev_station_img.png", // Placeholder, ideally use a battery asset or code it
                        height: 0, // Hiding placeholder
                        width: 0,
                      ),
                    ),
                    // Custom Battery Graphic Placeholder
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Battery Visual (Simple Rectangle)
                        Container(
                          width: 40,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 20, // 30% filled
                            width: double.infinity,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "212 km",
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  "14%",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "120 kw",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Saving Mode Battery",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Right Column: Distance + Temp
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildSmallStatCard(
                    isDark,
                    icon: Iconsax.direct_notification,
                    value: "1.345 km",
                    label: "Total Distance",
                  ),
                  const SizedBox(height: 16),
                  _buildSmallStatCard(
                    isDark,
                    icon: Iconsax.cloud,
                    value: "24°C",
                    label: "Partly Cloudy",
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallStatCard(
    bool isDark, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                size: 24,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark).copyWith(
        image: const DecorationImage(
          image: AssetImage(
            'assets/images/ChargingPage_bg.png',
          ), // Use existing map bg or placeholder
          fit: BoxFit.cover,
          opacity: 0.1, // Subtle map bg
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Find closest",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  "charging stations",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (Get.isRegistered<DashboardController>()) {
                      Get.find<DashboardController>().changeTabIndex(
                        1,
                      ); // Switch to Map Tab (Index 1)
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Get Directions",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.location, color: Colors.white),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
      border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
    );
  }
}
