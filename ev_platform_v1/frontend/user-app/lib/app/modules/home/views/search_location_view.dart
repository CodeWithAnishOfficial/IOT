import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // Add GoogleFonts
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_app/app/modules/home/controllers/home_controller.dart';
import 'package:user_app/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:user_app/app/modules/home/views/locate_on_map_view.dart';
import 'package:user_app/core/theme/app_theme.dart';
import 'package:user_app/core/theme/app_colors.dart';

class SearchLocationView extends GetView<HomeController> {
  final bool isEmbedded;
  final bool showBackButton;
  final bool isSavedTripMode;

  const SearchLocationView({
    super.key, 
    this.isEmbedded = false,
    this.showBackButton = false,
    this.isSavedTripMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final cardColor = theme.cardTheme.color;
    final scaffoldColor = theme.scaffoldBackgroundColor;
    final hintColor = theme.inputDecorationTheme.hintStyle?.color ?? Colors.grey;

    if (isEmbedded) {
      return _buildTripPlannerLayout(context, theme, isDark, textColor, cardColor, scaffoldColor);
    }
    return _buildSearchLayout(context, theme, isDark, textColor, cardColor, scaffoldColor);
  }

  Widget _buildTripPlannerLayout(BuildContext context, ThemeData theme, bool isDark, Color textColor, Color? cardColor, Color scaffoldColor) {
    // Attempt to find DashboardController to toggle navbar visibility
    DashboardController? dashboardController;
    if (Get.isRegistered<DashboardController>()) {
      dashboardController = Get.find<DashboardController>();
    }

    // Initial position (Bangalore/India fallback)
    final initialPos = controller.currentLocation.value != null
        ? LatLng(
            controller.currentLocation.value!.latitude,
            controller.currentLocation.value!.longitude,
          )
        : const LatLng(12.9716, 77.5946); // Bangalore

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: Stack(
        children: [
          // 1. Background Map
          Obx(() => GoogleMap(
            initialCameraPosition: CameraPosition(target: initialPos, zoom: 14),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            mapToolbarEnabled: false,
            padding: EdgeInsets.only(bottom: isSavedTripMode ? 0 : 350), // Adjust padding based on mode
            markers: controller.tripMarkers.toSet(),
            polylines: controller.tripPolylines.toSet(),
            onMapCreated: (GoogleMapController mapController) {
              controller.onTripMapCreated(mapController);
            },
            onCameraMoveStarted: () {
              controller.isTripMapDragging.value = true;
              dashboardController?.isNavBarVisible.value = false;
            },
            onCameraIdle: () {
              controller.isTripMapDragging.value = false;
              dashboardController?.isNavBarVisible.value = true;
            },
          )),

          // Back Button Area - Only show if from Saved Trips
          if (showBackButton)
            Positioned(
              top: 40,
              left: 16,
              child: CircleAvatar(
                backgroundColor: isDark ? Colors.black54 : Colors.white,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
                  onPressed: () {
                    if (isSavedTripMode) {
                      controller.cancelSavedTrip();
                    }
                    Get.back();
                  },
                ),
              ),
            ),

          // 2. Bottom Sheet Card
          Obx(() => AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: controller.isTripMapDragging.value ? -600 : -20,
            child: Builder(builder: (context) {
              if (controller.selectedStation.value != null) {
                return _buildStationDetailCard(context, theme, isDark);
              }
              if (controller.tripPolylines.isNotEmpty) {
                return _buildTripItinerarySheet(context, theme, isDark);
              }
              return _buildPlanningSheet(context, theme, isDark);
            }),
          )),

          // Current Location Button (Flexible Positioning)
          Obx(() {
            double bottomPos = 480; // Default for planning sheet

            if (controller.isTripMapDragging.value) {
              bottomPos = -100; // Hide to bottom when dragging
            } else if (controller.tripPolylines.isNotEmpty) {
              // Itinerary Sheet (Minimized/Expanded)
              // Minimized: 120 (height) + 110 (margin) + 20 (padding) = 250
              // Expanded: 450 (height) + 110 (margin) + 20 (padding) = 580
              bottomPos = controller.isItineraryMinimized.value ? 250 : 580;
            } else if (controller.selectedStation.value != null) {
              // Station Detail Card
              // Margin 120 + Content ~180 + Padding 20 = 320
              // Increased to 380 to be safely above the larger station card
              bottomPos = 380;
            } else {
              // Planning Sheet (Initial State)
              // Sheet height ~400 + 100 margin -> bottomPos ~500
              bottomPos = 520; 
            }

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: 16,
              bottom: bottomPos,
              child: FloatingActionButton(
                heroTag: "tripMyLocation",
                onPressed: () => controller.recenterMap(),
                backgroundColor: cardColor,
                foregroundColor: AppColors.primary,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                ),
                child: const Icon(Icons.my_location),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStationDetailCard(BuildContext context, ThemeData theme, bool isDark) {
    final station = controller.selectedStation.value!;
    final isAdded = controller.tripStops.any((s) => s.chargerId == station.chargerId);
    
    return Container(
      padding: const EdgeInsets.all(20),
      margin: EdgeInsets.fromLTRB(16, 16, 16, isSavedTripMode ? 16 : 120), // Float above nav bar
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.1),
             blurRadius: 20,
             offset: const Offset(0, 10),
           ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           // Header Row
           Row(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Expanded(
                 child: Text(
                   station.name ?? "Unknown Station",
                   style: GoogleFonts.poppins(
                     fontSize: 18,
                     fontWeight: FontWeight.w600,
                     color: theme.colorScheme.onSurface,
                   ),
                   maxLines: 2,
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
               const SizedBox(width: 8),
               InkWell(
                 onTap: () => controller.deselectStation(),
                 child: Container(
                   padding: const EdgeInsets.all(4),
                   decoration: BoxDecoration(
                     color: theme.dividerColor.withOpacity(0.1),
                     shape: BoxShape.circle,
                   ),
                   child: Icon(Icons.close, size: 20, color: theme.iconTheme.color),
                 ),
               ),
             ],
           ),
           const SizedBox(height: 4),
           // Address
           Text(
             station.location?.address ?? "Address not available",
             style: GoogleFonts.poppins(
               fontSize: 13,
               color: Colors.grey,
             ),
             maxLines: 2,
             overflow: TextOverflow.ellipsis,
           ),
           const SizedBox(height: 20),
           
           // Status & Distance
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                 decoration: BoxDecoration(
                   color: Colors.green.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(20),
                 ),
                 child: Row(
                   children: [
                     const Icon(Icons.check_circle, color: Colors.green, size: 14),
                     const SizedBox(width: 6),
                     Text(
                       "Available",
                       style: GoogleFonts.poppins(
                         color: Colors.green,
                         fontWeight: FontWeight.w600,
                         fontSize: 12,
                       ),
                     ),
                   ],
                 ),
               ),
               Text(
                 "${station.distance?.toStringAsFixed(1) ?? '--'} kms",
                 style: GoogleFonts.poppins(
                   color: Colors.grey,
                   fontSize: 13,
                   fontWeight: FontWeight.w500
                 ),
               ),
             ],
           ),
           const SizedBox(height: 20),
           
           // Action Button
           SizedBox(
             width: double.infinity,
             height: 52,
             child: ElevatedButton(
               onPressed: () {
                 if (isAdded) {
                   controller.tripStops.removeWhere((s) => s.chargerId == station.chargerId);
                   Get.snackbar(
                      "Removed", 
                      "Station removed from trip",
                      colorText: Colors.white, 
                      backgroundColor: Colors.red,
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                      snackPosition: SnackPosition.TOP
                   );
                 } else {
                   controller.tripStops.add(station);
                   Get.snackbar(
                      "Added", 
                      "Station added to trip", 
                      colorText: Colors.white, 
                      backgroundColor: Colors.green,
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                      snackPosition: SnackPosition.TOP
                   );
                 }
                 controller.deselectStation(); // Close card
               },
               style: ElevatedButton.styleFrom(
                 backgroundColor: isAdded ? Colors.redAccent : const Color(0xFFFF6B00),
                 elevation: 0,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
               ),
               child: Text(
                 isAdded ? "Remove station" : "Add station",
                 style: GoogleFonts.poppins(
                   color: Colors.white,
                   fontSize: 16,
                   fontWeight: FontWeight.w600,
                 ),
               ),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildTripItinerarySheet(BuildContext context, ThemeData theme, bool isDark) {
    return Obx(() {
      final isMinimized = controller.isItineraryMinimized.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: isSavedTripMode ? 0 : 110), // Float above nav bar only if embedded
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Allow growing based on content
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${controller.sourceController.text.split(',')[0]} - ${controller.destinationController.text.split(',')[0]}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "via Optimized Route", // Mock
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                   onPressed: controller.currentSavedTripId.value != null 
                     ? null 
                     : () => _showSaveTripDialog(context),
                   icon: Icon(
                     controller.currentSavedTripId.value != null ? Icons.bookmark : Icons.bookmark_border,
                     color: theme.iconTheme.color,
                   ),
                ),
                IconButton(
                  icon: Icon(
                    isMinimized
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: () => controller.toggleItineraryMinimize(),
                ),
              ],
            ),
            
            // Collapsible Content
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: isMinimized 
               ? const SizedBox.shrink() 
               : Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Divider(color: isDark ? Colors.white10 : Colors.black12),
                     
                     // List
                     Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          children: [
                            // Source
                            _buildItineraryItem(
                              icon: Icons.circle,
                              iconColor: Colors.blue,
                              title:
                                  controller.sourceController.text.isEmpty
                                      ? "Current Location"
                                      : controller.sourceController.text,
                              subtitle:
                                  "Departure SoC - ${controller.departureSoC.value.toInt()}%",
                              isLast: false,
                              textColor: theme.colorScheme.onSurface,
                            ),

                            // Stops
                            ...controller.tripStops.asMap().entries.map((entry) {
                              final index = entry.key;
                              final stop = entry.value;
                              return _buildItineraryItem(
                                icon: Icons.location_on, 
                                customIcon: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Colors.deepOrange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${index + 1}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                title: stop.name ?? "Station",
                                subtitle: "Stop ${index + 1}",
                                isLast: false,
                                isStop: true,
                                onDelete: () => controller.tripStops.remove(stop),
                                textColor: theme.colorScheme.onSurface,
                              );
                            }).toList(),

                            // Destination
                            _buildItineraryItem(
                              icon: Icons.location_on,
                              iconColor: Colors.red,
                              title: controller.destinationController.text,
                              subtitle:
                                  "Arrival SoC - ${controller.arrivalSoC.value.toInt()}% (approx)",
                              isLast: true,
                              textColor: theme.colorScheme.onSurface,
                            ),
                          ],
                        ),
                     ),
                     
                     // Action Buttons
                     Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: () {
                                    if (isSavedTripMode) {
                                      controller.cancelSavedTrip();
                                      Get.back();
                                    } else {
                                      controller.clearSearch();
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ), 
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    controller.launchGoogleMapsNavigation();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Start",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                   ],
               ),
            ),
          ],
        ),
      );
    });
  }

  void _showSaveTripDialog(BuildContext context) {
      final textController = TextEditingController();
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      Get.bottomSheet(
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Save Trip",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: textController,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Trip Name',
                    hintText: "Enter trip name",
                    prefixIcon: const Icon(Icons.bookmark_border),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (textController.text.isNotEmpty) {
                        Get.back();
                        controller.saveCurrentTrip(textController.text);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Save Trip",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        isScrollControlled: true,
      );
  }

  Widget _buildItineraryItem({
    required IconData icon,
    Color iconColor = Colors.grey,
    required String title,
    required String subtitle,
    required bool isLast,
    bool isStop = false,
    Widget? customIcon,
    VoidCallback? onDelete,
    Color? textColor,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              if (customIcon != null)
                customIcon
              else
                Icon(icon, color: iconColor, size: 20),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.withOpacity(0.3), // Light line
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor ?? Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isStop ? Colors.grey : (subtitle.contains("Departure") ? Colors.red[300] : Colors.green[400]), // Colored subtitle
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: onDelete,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanningSheet(BuildContext context, ThemeData theme, bool isDark) {
    final bool fromSaved = Get.arguments != null && Get.arguments is Map && Get.arguments['fromSaved'] == true;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 20, 16, fromSaved ? 20 : 100), // Increased bottom padding for nav bar only if embedded
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Plan your next trip",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18, // Reduced size
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tackle your range anxiety with our hassle-free charging experience on your next trip.",
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12, // Reduced size
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16), // Reduced spacing

            // Inputs Card
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5), // Darker inner bg or lighter
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                      ),
                      child: Column(
                        children: [
                          // Start Location
                          InkWell(
                            onTap: () {
                               controller.searchMode.value = 'trip'; // Ensure trip mode
                               controller.activeField.value = 'source';
                               Get.to(() => const SearchLocationView(isEmbedded: false), transition: Transition.downToUp);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white54 : Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ValueListenableBuilder<TextEditingValue>(
                                          valueListenable: controller.sourceController,
                                          builder: (context, value, child) {
                                            return Obx(() {
                                              final currentAddr = controller.currentAddress.value;
                                              final displayText = value.text.isEmpty
                                                  ? (currentAddr.isNotEmpty && currentAddr != "Locating..."
                                                      ? currentAddr
                                                      : "Current Location")
                                                  : value.text;

                                              return Text(
                                                displayText,
                                                style: TextStyle(
                                                  color: theme.colorScheme.onSurface,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // SoC Slider for Departure
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                           Obx(() => Text(
                                            "Departure SoC - ${controller.departureSoC.value.toInt()}%",
                                            style: TextStyle(
                                              color: isDark ? Colors.white70 : Colors.black54,
                                              fontSize: 12,
                                            ),
                                          )),
                                          Icon(Icons.swap_vert, color: isDark ? Colors.white24 : Colors.black26, size: 16),
                                        ],
                                      ),
                                      Obx(() => SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 4,
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                          activeTrackColor: _getSoCColor(controller.departureSoC.value),
                                          inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
                                          thumbColor: isDark ? Colors.white : AppColors.primary,
                                        ),
                                        child: Slider(
                                          value: controller.departureSoC.value,
                                          min: 0,
                                          max: 100,
                                          onChanged: (val) => controller.departureSoC.value = val,
                                        ),
                                      )),
                                      Text(
                                        "*adjust the slider according to your preference",
                                        style: TextStyle(
                                          color: Colors.red[300],
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                          
                          // Destination
                          InkWell(
                            onTap: () {
                               controller.searchMode.value = 'trip'; // Ensure trip mode
                               controller.activeField.value = 'destination';
                               Get.to(() => const SearchLocationView(isEmbedded: false), transition: Transition.downToUp);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary, // Highlight color
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ValueListenableBuilder<TextEditingValue>(
                                          valueListenable: controller.destinationController,
                                          builder: (context, value, child) {
                                            return Text(
                                              value.text.isEmpty 
                                                  ? "Enter Destination" 
                                                  : value.text,
                                              style: TextStyle(
                                                color: value.text.isEmpty 
                                                    ? (isDark ? Colors.grey : Colors.grey[600])
                                                    : theme.colorScheme.onSurface,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Arrival SoC (Read Only)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Arrival SoC - 0% (approx)",
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Select Station Button
                    Obx(() {
                      final hasSource = controller.sourceLatLng.value != null;
                      final hasDest = controller.destinationLatLng.value != null;
                      
                      if (!hasSource || !hasDest) {
                        return const SizedBox.shrink(); 
                      }

                      return SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                             controller.planTripFromEmbedded();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange, // Orange like screenshot
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Select Station",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }

  Color _getSoCColor(double value) {
    if (value > 50) return Colors.green;
    if (value > 20) return Colors.orange;
    return Colors.red;
  }

  Widget _buildSearchLayout(BuildContext context, ThemeData theme, bool isDark, Color textColor, Color? cardColor, Color scaffoldColor) {
    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ),
        automaticallyImplyLeading: true,
        title: Obx(
          () => Text(
            controller.searchMode.value == 'explore'
                ? "Search Location"
                : "Set a Trip",
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Inputs Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Source Input (Hidden in explore mode)
                Obx(
                  () => controller.searchMode.value == 'explore'
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            _buildInputRow(
                              context: context,
                              controller: controller.sourceController,
                              hint: controller.currentAddress.value.isNotEmpty &&
                                      controller.currentAddress.value != "Locating..."
                                  ? controller.currentAddress.value
                                  : "Current Location",
                              icon: Icons.my_location,
                              iconColor: Colors.blue,
                              isSource: true,
                              theme: theme,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                ),
                // Destination Input
                Obx(
                  () => _buildInputRow(
                    context: context,
                    controller: controller.destinationController,
                    hint: controller.searchMode.value == 'explore'
                        ? "Search for a place"
                        : "Enter Destination",
                    icon: Icons.location_on,
                    iconColor: Colors.red,
                    isSource: false,
                    theme: theme,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),

          // Search Results
          Expanded(
            child: Obx(() {
              if (controller.isSearching.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.searchError.isNotEmpty) {
                return Center(
                    child: Text(controller.searchError.value,
                        style: TextStyle(color: textColor)));
              }

              // Show results if searching
              if (controller.searchResults.isNotEmpty) {
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: controller.searchResults.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 72,
                    endIndent: 16,
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                  ),
                  itemBuilder: (context, index) {
                    final result = controller.searchResults[index];
                    final description = result['description'] ?? '';
                    final mainText =
                        result['structured_formatting']?['main_text'] ??
                            description.split(',')[0];
                    final secondaryText =
                        result['structured_formatting']?['secondary_text'] ??
                            description;
                    final placeId = result['place_id'] ?? '';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        mainText,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        secondaryText,
                        style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                          // Handle selection
                          controller.onPlaceSelected(placeId, description);
                      },
                    );
                  },
                );
              }

              // No results found state
              if (controller.searchController.text.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Location not found",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Please try a different address or locate on\nthe map",
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              // Default View (Recents only)
              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (controller.recentSearches.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        "Recent Searches",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...controller.recentSearches.map((recent) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: const Icon(
                          Icons.history,
                          color: Colors.grey,
                          size: 22,
                        ),
                        title: Text(
                          recent['description'] ?? '',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => controller.onPlaceSelected(
                          recent['placeId']!,
                          recent['description']!,
                        ),
                      );
                    }).toList(),
                  ],
                ],
              );
            }),
          ),

          // Bottom Action Bar (Current Location | Locate on Map)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: controller.useCurrentLocation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.my_location,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Current Location",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                    height: 24, width: 1, color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
                Expanded(
                  child: InkWell(
                    onTap: () => Get.to(
                      () => const LocateOnMapView(),
                      transition: Transition.rightToLeft,
                      duration: const Duration(milliseconds: 300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Locate on map",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required bool isSource,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
      ),
      child: Focus(
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            this.controller.activeField.value = isSource
                ? 'source'
                : 'destination';
            // Clear search results when switching fields
            this.controller.searchResults.clear();
          }
        },
        child: TextField(
          controller: controller,
          onChanged: this.controller.onSearchChanged,
          style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[500]),
            prefixIcon: Icon(icon, color: iconColor),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                return value.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          controller.clear();
                          this.controller.searchResults.clear();
                        },
                      )
                    : const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }
}
