import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:user_app/app/modules/session_history/controllers/session_history_controller.dart';
import 'package:user_app/app/modules/session_history/domain/models/charging_session.dart';
import 'package:user_app/app/modules/session_history/views/session_detail_view.dart';
import 'package:user_app/core/theme/app_colors.dart';

import 'package:user_app/core/widgets/shimmer/shimmer_box.dart';

class SessionView extends GetView<SessionHistoryController> {
  const SessionView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          "History",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List of Sessions
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: 5, // Show 5 shimmer items
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _buildShimmerItem(context),
                  );
                }

                if (controller.sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.ev_station_outlined,
                          size: 64,
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No charging sessions found",
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.fetchSessions,
                  color: AppColors.primary,
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: controller.sessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final session = controller.sessions[index];
                      return _buildSessionCard(context, session);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, ChargingSession session) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = session.status.toLowerCase() == 'active';
    final dateStr = DateFormat('MMM dd, yyyy').format(session.startTime);
    final timeStr = DateFormat('HH:mm').format(session.startTime);

    return GestureDetector(
      onTap: () => Get.to(() => SessionDetailView(session: session)),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // Icon / Date Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive 
                    ? AppColors.success.withOpacity(0.1) 
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('MMM').format(session.startTime).toUpperCase(),
                    style: GoogleFonts.orbitron(
                      color: isActive ? AppColors.success : Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd').format(session.startTime),
                    style: GoogleFonts.poppins(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Station ID: ${session.chargerId}",
                    style: GoogleFonts.poppins(
                      color: theme.textTheme.titleMedium?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.flash_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "${session.totalEnergy.toStringAsFixed(1)} kWh",
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.schedule, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Cost
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${session.cost.toStringAsFixed(2)}",
                  style: GoogleFonts.orbitron(
                    color: AppColors.success,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.success : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? "Active" : "Paid",
                    style: GoogleFonts.poppins(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerItem(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Icon Box Shimmer
          ShimmerBox(
            width: 50,
            height: 60,
            borderRadius: 16,
            baseColor: isDark ? Colors.white10 : Colors.grey[200],
            highlightColor: isDark ? Colors.white24 : Colors.grey[100],
          ),
          const SizedBox(width: 16),

          // Info Column Shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: 120,
                  height: 16,
                  baseColor: isDark ? Colors.white10 : Colors.grey[200],
                  highlightColor: isDark ? Colors.white24 : Colors.grey[100],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ShimmerBox(
                      width: 60,
                      height: 12,
                      baseColor: isDark ? Colors.white10 : Colors.grey[200],
                      highlightColor: isDark ? Colors.white24 : Colors.grey[100],
                    ),
                    const SizedBox(width: 12),
                    ShimmerBox(
                      width: 40,
                      height: 12,
                      baseColor: isDark ? Colors.white10 : Colors.grey[200],
                      highlightColor: isDark ? Colors.white24 : Colors.grey[100],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Cost Column Shimmer
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShimmerBox(
                width: 70,
                height: 20,
                baseColor: isDark ? Colors.white10 : Colors.grey[200],
                highlightColor: isDark ? Colors.white24 : Colors.grey[100],
              ),
              const SizedBox(height: 8),
              ShimmerBox(
                width: 50,
                height: 14,
                borderRadius: 4,
                baseColor: isDark ? Colors.white10 : Colors.grey[200],
                highlightColor: isDark ? Colors.white24 : Colors.grey[100],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
