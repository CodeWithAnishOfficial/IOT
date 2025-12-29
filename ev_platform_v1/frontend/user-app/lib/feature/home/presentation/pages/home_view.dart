import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_app/feature/home/presentation/controllers/home_controller.dart';
import 'package:user_app/feature/home/presentation/widgets/side_menu.dart';
import 'package:user_app/feature/home/presentation/widgets/station_detail_sheet.dart';
import 'package:user_app/utils/theme/themes.dart';

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
      resizeToAvoidBottomInset: false,
      drawer: const SideMenu(),
      body: Stack(
        children: [
          // 1. Full Screen Map
          Obx(
            () => GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(28.6139, 77.2090), // Default New Delhi
                zoom: 12,
              ),
              onMapCreated: controller.onMapCreated,
              markers: controller.markers.toSet(),
              polylines: controller.polylines.toSet(),
              myLocationEnabled: controller.isLocationGranted.value,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              padding: const EdgeInsets.only(
                bottom: 220,
              ), // Push Google logo up above sheet
            ),
          ),

          // 2. Top Navigation Bar (Ola Style)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
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
                  // Hamburger Menu
                  InkWell(
                    onTap: () => scaffoldKey.currentState?.openDrawer(),
                    child: const Icon(Icons.menu, color: Colors.black87),
                  ),
                  const SizedBox(width: 16),

                  // Green Dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
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
                            color: Colors.black87,
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
                    child: const Icon(Icons.qr_code_scanner, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),

          // 3. Clear Polyline Button (Below Header)
          Obx(() => controller.polylines.isNotEmpty
              ? Positioned(
                  top: MediaQuery.of(context).padding.top + 90,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: "clearPolyline",
                    onPressed: () => controller.clearSearch(),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    elevation: 4,
                    child: const Icon(Icons.close_rounded),
                  ),
                )
              : const SizedBox.shrink()),

          // 4. Current Location & Plan Trip Buttons
          Positioned(
            right: 20,
            bottom: 250, // Adjusted to sit above the lower sheet
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Plan Trip Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FloatingActionButton(
                    heroTag: "planTrip",
                    onPressed: () => controller.openSearch(mode: 'trip'),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 4,
                    child: const Icon(Icons.directions),
                  ),
                ),

                FloatingActionButton(
                  heroTag: "myLocation",
                  onPressed: () => controller.recenterMap(),
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  elevation: 4,
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
                          color: Colors.white,
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text("Searching area..."),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // 5. Draggable Bottom Sheet (Ola Style)
          HomeBottomSheet(controller: controller),

        ],
      ),
    );
  }

  Widget _buildRecentItem({required String title, required IconData icon}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.grey[600], size: 20),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: () {},
    );
  }
}

class HomeBottomSheet extends StatefulWidget {
  final HomeController controller;
  
  const HomeBottomSheet({super.key, required this.controller});

  @override
  State<HomeBottomSheet> createState() => _HomeBottomSheetState();
}

class _HomeBottomSheetState extends State<HomeBottomSheet> {
  late DraggableScrollableController _sheetController;
  late StreamSubscription<double> _sheetSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize the controller - tied to this specific widget instance
    _sheetController = DraggableScrollableController();
    
    // Listen to animation requests
    _sheetSubscription = widget.controller.sheetAnimationStream.listen((height) {
      if (_sheetController.isAttached) {
        _sheetController.animateTo(
          height,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _sheetSubscription.cancel();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.28,
      minChildSize: 0.28,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Obx(() {
           if (widget.controller.selectedStation.value != null) {
             return StationDetailSheet(
               station: widget.controller.selectedStation.value!,
               scrollController: scrollController,
               controller: widget.controller,
             );
           }
        
           return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 20),

                // 1. Nearby Chargers Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: const Text(
                    "Nearby Chargers",
                    style: TextStyle(
                      fontSize: 16, // Reduced
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(
                  height: 145, // Minimized height
                  child: Obx(() {
                    if (widget.controller.stations.isEmpty) {
                      return Center(
                        child: Text(
                          "No chargers found nearby",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }
                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification) {
                          // Item width (300) + Separator (12) = 312
                          final double offset = notification.metrics.pixels;
                          final int index = (offset / 312).round();
                          if (index >= 0 &&
                              index < widget.controller.stations.length) {
                            widget.controller
                                .animateToStation(widget.controller.stations[index]);
                          }
                        }
                        return true;
                      },
                      child: ListView.separated(
                        controller: widget.controller.stationScrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.controller.stations.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final station = widget.controller.stations[index];
                          final isOnline = station.status.toLowerCase() == 'online';
                          
                          return GestureDetector(
                            onTap: () => widget.controller.selectStation(station),
                            child: Container(
                              width: 300, // Minimalist width
                              margin: const EdgeInsets.symmetric(vertical: 4), 
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header: Name + Status Dot
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          station.name ?? "Unknown Station",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.3,
                                            color: Colors.black,
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
                                          color: isOnline ? Colors.green : Colors.red,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isOnline ? Colors.green : Colors.red).withOpacity(0.4),
                                              blurRadius: 4,
                                            )
                                          ]
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    station.location?.address ?? "Address not available",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  const Spacer(),
                                  
                                  // Footer: Stats + Action
                                  Row(
                                    children: [
                                      // Power
                                      Icon(Icons.flash_on_rounded, size: 16, color: Colors.amber[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${station.maxPowerKw?.toInt() ?? '--'} kW",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 16),
                                      
                                      // Plugs
                                      Icon(Icons.ev_station_rounded, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${station.connectors.length}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      
                                      const Spacer(),
                                      
                                      // Distance
                                      if (station.distance != null)
                                        Text(
                                          "${station.distance!.toStringAsFixed(1)} km",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        
                                      const SizedBox(width: 12),
                                      
                                      // Nav Button
                                      InkWell(
                                        onTap: () => widget.controller.startNavigation(station),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: const BoxDecoration(
                                            color: Colors.black,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.near_me_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
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
                
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          );
        });
      },
    );
  }
}
