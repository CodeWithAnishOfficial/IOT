import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_app/app/modules/home/controllers/home_controller.dart';
import 'package:user_app/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:user_app/app/modules/home/widgets/side_menu.dart';
import 'package:user_app/app/modules/home/widgets/station_detail_sheet.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_theme.dart';

import 'package:user_app/core/widgets/shimmer/shimmer_box.dart'; // Import ShimmerBox

import 'package:user_app/app/modules/home/widgets/location_pill.dart';
import 'package:user_app/app/modules/home/widgets/station_card_new.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeController controller = Get.find<HomeController>();
  DashboardController? dashboardController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<DashboardController>()) {
      dashboardController = Get.find<DashboardController>();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    controller.updateMapStyle(isDark);
  }

  @override
  Widget build(BuildContext context) {
    // Key to control the scaffold drawer
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: scaffoldKey,
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor, // Theme background
      resizeToAvoidBottomInset: false,
      drawer: const SideMenu(),
      body: Stack(
        children: [
          // 1. Full Screen Map
          Obx(() {
            return Stack(
              children: [
                // Actual Map (Always present if position known)
                if (controller.initialCameraPosition.value != null)
                  GoogleMap(
                    key: const ValueKey("google_map"), // Preserve State
                    initialCameraPosition: controller.initialCameraPosition.value!,
                    onMapCreated: controller.onMapCreated,
                    markers: controller.markers.toSet(),
                    polylines: controller.polylines.toSet(),
                    myLocationEnabled: controller.isLocationGranted.value,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    padding: EdgeInsets.zero, // Remove padding
                    onCameraMoveStarted: () {
                      // Only hide navbar if user is dragging (not programmatic animation)
                      if (!controller.isProgrammaticMapMove.value) {
                        dashboardController?.isNavBarVisible.value = false;
                      }
                    },
                    onCameraIdle: () {
                      controller.isProgrammaticMapMove.value = false;
                      dashboardController?.isNavBarVisible.value = true;
                    },
                    onTap: (_) {
                       dashboardController?.isNavBarVisible.value = true;
                    },
                  ),
                  
                // Loading Overlay (Fades out when map is ready)
                IgnorePointer(
                  ignoring: controller.isMapReady.value,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: controller.isMapReady.value ? 0.0 : 1.0,
                    child: Container(
                      color: theme.scaffoldBackgroundColor,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),

          // 2. Top Floating UI
          Obx(() {
            final isVisible = dashboardController?.isNavBarVisible.value ?? true;
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              top: isVisible ? MediaQuery.of(context).padding.top + 16 : -150,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  // Top Row: Menu - Search - Profile
                  Row(
                    children: [
                      // Menu Button
                      _buildFloatingButton(
                        theme,
                        icon: Icons.menu,
                        onTap: () => scaffoldKey.currentState?.openDrawer(),
                      ),
                      const SizedBox(width: 12),

                      // Search Bar
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.openSearch(mode: 'explore'),
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: theme.iconTheme.color?.withOpacity(0.6),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Search chargers...",
                                  style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // QR Scanner Button
                      _buildFloatingButton(
                        theme,
                        icon: Icons.qr_code_scanner,
                        onTap: () => controller.scanQrCode(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),

                  // Location Pill (Centered or Floating below)
                  Obx(() => LocationPill(
                    location: controller.currentAddress.value,
                    onTap: () => controller.openSearch(mode: 'explore'), // Or toggle current location
                  )),
                ],
              ),
            );
          }),

          // 5. Loading Indicator
          Obx(
            () => controller.isLoading.value
                ? Positioned(
                    top: 100,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: theme.shadowColor.withOpacity(0.1), blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Searching area...",
                              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // 5. Fixed Bottom Section (Floating Cards or Detail Sheet)
          Obx(() {
            final isNavBarVisible = dashboardController?.isNavBarVisible.value ?? true;
            final bottomPadding = isNavBarVisible ? 100.0 : 30.0;
            
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              bottom: bottomPadding, // Floating above bottom
              child: SizedBox(
                  height: 180, // Height for StationCard + Padding
                  child: Obx(() {
                    if (controller.isLoading.value && controller.stations.isEmpty) {
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        separatorBuilder: (_, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) => const ShimmerBox(
                          width: 300,
                          height: 160,
                          borderRadius: 24,
                        ),
                      );
                    }
                    
                    if (controller.stations.isEmpty) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Text(
                                "No chargers found nearby",
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return PageView.builder(
                      controller: controller.pageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: controller.stations.length,
                      onPageChanged: (index) {
                        final station = controller.stations[index];
                        controller.animateToStation(station);
                        dashboardController?.isNavBarVisible.value = true;
                      },
                      itemBuilder: (context, index) {
                        final station = controller.stations[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10), // Shadow space
                          child: StationCard(
                            station: station,
                            onTap: () => controller.navigateToStationDetails(station),
                            onNavigate: () => controller.launchMaps(station),
                          ),
                        );
                      },
                    );
                  }),
                ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(ThemeData theme, {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: theme.iconTheme.color,
          size: 24,
        ),
      ),
    );
  }
}
