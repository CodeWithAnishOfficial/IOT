import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/app/modules/trip/controllers/trip_controller.dart';
import 'package:user_app/app/routes/app_routes.dart';
import 'package:user_app/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/widgets/shimmer/shimmer_box.dart';

class SavedTripsView extends StatefulWidget {
  const SavedTripsView({super.key});

  @override
  State<SavedTripsView> createState() => _SavedTripsViewState();
}

class _SavedTripsViewState extends State<SavedTripsView> {
  // Controller is bound by TripBinding via Route
  final TripController controller = Get.find<TripController>();
  final ScrollController _scrollController = ScrollController();
  
  DashboardController? _dashboardController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<DashboardController>()) {
      _dashboardController = Get.find<DashboardController>();
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (_dashboardController != null) {
            if (notification.direction == ScrollDirection.reverse) {
              if (_dashboardController!.isNavBarVisible.value) {
                _dashboardController!.isNavBarVisible.value = false;
              }
            } else if (notification.direction == ScrollDirection.forward) {
              if (!_dashboardController!.isNavBarVisible.value) {
                _dashboardController!.isNavBarVisible.value = true;
              }
            }
          }
          return true;
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              surfaceTintColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              pinned: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                onPressed: () => Get.back(),
              ),
              title: Text(
                "Saved Trips",
                style: GoogleFonts.poppins(
                  color: theme.textTheme.titleLarge?.color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),

            // Content List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: Obx(() {
                if (controller.isLoading.value) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildShimmerItem(context),
                      childCount: 5,
                    ),
                  );
                }

                if (controller.savedTrips.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 50),
                          Icon(Icons.map_outlined, color: theme.disabledColor, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            "No saved trips yet",
                            style: GoogleFonts.poppins(color: theme.disabledColor),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final trip = controller.savedTrips[index];
                      return _buildTripCard(context, trip);
                    },
                    childCount: controller.savedTrips.length,
                  ),
                );
              }),
            ),
            
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, dynamic trip) {
    final theme = Theme.of(context);


    return GestureDetector(
      onTap: () {
        controller.loadSavedTrip(trip);
        Get.toNamed(Routes.TRIP_PLANNER);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            // Icon / Type Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    "TRIP",
                    style: GoogleFonts.orbitron(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.route_outlined,
                    color: theme.textTheme.bodyLarge?.color,
                    size: 20,
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
                    trip.name,
                    style: GoogleFonts.poppins(
                      color: theme.textTheme.titleMedium?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.trip_origin, size: 12, color: Colors.blue[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          trip.source.address,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                   Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.red[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          trip.destination.address,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),

            // Actions
            Column(
              children: [
                _buildActionBtn(
                  icon: Icons.play_arrow_rounded,
                  color: AppColors.success,
                  onTap: () {
        controller.loadSavedTrip(trip);
        Get.toNamed(Routes.TRIP_PLANNER);
      },
                ),
                const SizedBox(height: 8),
                _buildActionBtn(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.error,
                  onTap: () => _confirmDelete(context, trip.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildShimmerItem(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
            ShimmerBox(
              width: 50,
              height: 60,
              borderRadius: 16,
              baseColor: isDark ? Colors.white10 : Colors.grey[200],
              highlightColor: isDark ? Colors.white24 : Colors.grey[100],
            ),
            const SizedBox(width: 16),
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
                  ShimmerBox(
                    width: double.infinity,
                    height: 12,
                    baseColor: isDark ? Colors.white10 : Colors.grey[200],
                    highlightColor: isDark ? Colors.white24 : Colors.grey[100],
                  ),
                  const SizedBox(height: 4),
                  ShimmerBox(
                    width: 100,
                    height: 12,
                    baseColor: isDark ? Colors.white10 : Colors.grey[200],
                    highlightColor: isDark ? Colors.white24 : Colors.grey[100],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                ShimmerBox(width: 32, height: 32, borderRadius: 8),
                const SizedBox(height: 8),
                ShimmerBox(width: 32, height: 32, borderRadius: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String tripId) {
    final theme = Theme.of(context);
    Get.dialog(
      Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                "Delete Trip?",
                style: GoogleFonts.poppins(
                  color: theme.textTheme.titleLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "This action cannot be undone.",
                style: GoogleFonts.poppins(color: theme.textTheme.bodyMedium?.color, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text("Cancel", style: GoogleFonts.poppins(color: theme.textTheme.bodyMedium?.color)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.deleteSavedTrip(tripId);
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Delete", style: GoogleFonts.poppins(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
