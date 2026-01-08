import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_app/feature/home/presentation/controllers/home_controller.dart';
import 'package:user_app/feature/home/presentation/widgets/side_menu.dart';
import 'package:user_app/feature/home/presentation/widgets/station_detail_sheet.dart';
import 'package:user_app/utils/theme/themes.dart';

import 'package:user_app/utils/widgets/shimmer/shimmer_box.dart'; // Import ShimmerBox

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeController controller = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    // Key to control the scaffold drawer
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      extendBody: true,
      backgroundColor: const Color(0xFF121212), // Dark background for map loading
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
                  ),
                  
                // Loading Overlay (Fades out when map is ready)
                IgnorePointer(
                  ignoring: controller.isMapReady.value,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: controller.isMapReady.value ? 0.0 : 1.0,
                    child: Container(
                      color: const Color(0xFF121212),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),

          // 2. Top Navigation Bar (Ola Style)
          Positioned(
            top: MediaQuery.of(context).padding.top + 30, // Increased top spacing
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E), // Match station card background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Hamburger Menu
                  InkWell(
                    onTap: () => scaffoldKey.currentState?.openDrawer(),
                    child: const Icon(
                      Icons.menu,
                      color: Colors.white,
                    ), // White icon
                  ),
                  const SizedBox(width: 16),

                  // Green Dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor, // Neon Lime
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Location Text
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.openSearch(mode: 'explore'),
                      child: Obx(
                        () => Text(
                          controller.currentAddress.value,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white, // White text
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),

                  // QR Scanner Icon
                  InkWell(
                    onTap: () => controller.scanQrCode(),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Clear Polyline Button (Below Header)
          Obx(
            () => controller.polylines.isNotEmpty
                ? Positioned(
                    top: MediaQuery.of(context).padding.top + 104, // Adjusted for new header position
                    right: 16,
                    child: FloatingActionButton.small(
                      heroTag: "clearPolyline",
                      onPressed: () => controller.clearSearch(),
                      backgroundColor: Colors.red.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      child: const Icon(Icons.close_rounded),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // 4. Current Location & Plan Trip Buttons
          Positioned(
            right: 20,
            bottom: 300, // Raised to avoid overlapping with Station Cards (120 + 160 + padding)
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Plan Trip Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FloatingActionButton(
                    heroTag: "planTrip",
                    onPressed: () => controller.openSearch(mode: 'trip'),
                    backgroundColor: const Color(0xFF1E1E1E), // Match station card background
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(Icons.directions),
                  ),
                ),

                FloatingActionButton(
                  heroTag: "myLocation",
                  onPressed: () => controller.recenterMap(),
                  backgroundColor: const Color(0xFF1E1E1E), // Match station card background
                  foregroundColor: AppTheme.primaryColor,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

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
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Searching area...",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // 5. Fixed Bottom Section (Tiny Cards or Detail Sheet)
          Positioned(
            left: 0,
            right: 0,
            bottom: 120, // Raised to clear floating navbar (72 + 34 + padding)
            child: Obx(() {
              // 5a. Detail Sheet
              if (controller.selectedStation.value != null) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.75, // Reduced slightly as it's higher up
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: StationDetailSheet(
                      station: controller.selectedStation.value!,
                      scrollController: ScrollController(),
                      controller: controller,
                    ),
                  ),
                );
              }

              // 5b. Tiny Cards List
              return Container(
                height: 160, // Increased height for better visibility
                padding: const EdgeInsets.only(bottom: 30),
                child: SizedBox(
                  height: 130, // Increased card height
                  child: Obx(() {
                    if (controller.isLoading.value && controller.stations.isEmpty) {
                      return ListView.separated(
                        padding: const EdgeInsets.only(left: 72, right: 16), // Align with Green Dot
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        separatorBuilder: (_, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) => const ShimmerBox(
                          width: 260,
                          height: 130,
                          borderRadius: 16,
                          baseColor: Color(0xFF121212),
                          highlightColor: Color(0xFF252525),
                        ),
                      );
                    }
                    
                    if (controller.stations.isEmpty) {
                      return Center(
                        child: Container(
                          width: 320,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "No chargers found nearby",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "We will be updating chargers in this location soon.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification) {
                          // Calculate center index based on scroll offset
                          // Card width (260) + Separator (12) = 272
                          final double itemWidth = 272.0;
                          final offset = controller.stationScrollController.offset;

                          // Current index
                          int index = (offset / itemWidth).round();

                          // Bounds check
                          if (index < 0) index = 0;
                          if (index >= controller.stations.length) {
                            index = controller.stations.length - 1;
                          }

                          if (controller.stations.isNotEmpty) {
                            final station = controller.stations[index];
                            // Animate map to this station
                            controller.animateToStation(station, offsetLat: -0.002);
                          }
                        }
                        return false;
                      },
                      child: ListView.separated(
                        controller: controller.stationScrollController,
                        padding: const EdgeInsets.only(left: 72, right: 16), // Align with Green Dot
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.stations.length,
                        separatorBuilder: (_, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                        final station = controller.stations[index];
                        final isOnline = station.status.toLowerCase() == 'online';

                        return GestureDetector(
                          onTap: () => controller.selectStation(station),
                          child: Container(
                            width: 260, // Increased Width
                            padding: const EdgeInsets.all(16), // Consistent Padding
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E), // Slightly lighter than black for depth
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1), 
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Top Row: Name and Status Dot
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        station.name ?? "Unknown Station",
                                        style: const TextStyle(
                                          fontSize: 16, 
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isOnline ? AppTheme.primaryColor : Colors.red,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isOnline ? AppTheme.primaryColor : Colors.red).withOpacity(0.5),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Address / Location Hint
                                Text(
                                  station.location?.address ?? "Location info unavailable",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const Divider(color: Colors.white10, height: 16),

                                // Bottom Row: Distance, Power, and Connectors
                                Row(
                                  children: [
                                    // Distance
                                    Icon(Icons.directions, size: 14, color: AppTheme.primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${station.distance?.toStringAsFixed(1) ?? '--'} km",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    
                                    const Spacer(),
                                    
                                    // Power Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.white12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.flash_on, size: 12, color: Colors.orangeAccent),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${station.maxPowerKw?.toInt() ?? 0}kW",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

