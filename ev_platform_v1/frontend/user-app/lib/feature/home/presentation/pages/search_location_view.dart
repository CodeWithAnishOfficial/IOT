import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // Add GoogleFonts
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_app/feature/home/presentation/controllers/home_controller.dart';
import 'package:user_app/feature/home/presentation/pages/locate_on_map_view.dart';
import 'package:user_app/utils/theme/themes.dart';

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
    if (isEmbedded) {
      return _buildTripPlannerLayout(context);
    }
    return _buildSearchLayout(context);
  }

  Widget _buildTripPlannerLayout(BuildContext context) {
    // Initial position (Bangalore/India fallback)
    final initialPos = controller.currentLocation.value != null
        ? LatLng(
            controller.currentLocation.value!.latitude,
            controller.currentLocation.value!.longitude,
          )
        : const LatLng(12.9716, 77.5946); // Bangalore

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
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
          )),

          // Back Button Area - Only show if from Saved Trips
          if (showBackButton)
            Positioned(
              top: 40,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
              ),
            ),

          // 2. Bottom Sheet Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Obx(() {
               if (controller.selectedStation.value != null) {
                 return _buildStationDetailCard(context);
               }
               if (controller.tripPolylines.isNotEmpty) {
                 return _buildTripItinerarySheet(context);
               }
               return _buildPlanningSheet(context);
            }),
          ),

          // Current Location Button (Flexible Positioning)
          Obx(() {
            double bottomPos = 480; // Default for planning sheet

            if (controller.tripPolylines.isNotEmpty) {
              // Itinerary Sheet (Minimized/Expanded)
              // Minimized: 120 (height) + 110 (margin) + 20 (padding) = 250
              // Expanded: 450 (height) + 110 (margin) + 20 (padding) = 580
              bottomPos = controller.isItineraryMinimized.value ? 250 : 580;
            } else if (controller.selectedStation.value != null) {
              // Station Detail Card
              // Margin 120 + Content ~180 + Padding 20 = 320
              bottomPos = 320;
            }

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: 16,
              bottom: bottomPos,
              child: FloatingActionButton(
                heroTag: "tripMyLocation",
                onPressed: () => controller.recenterMap(),
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: AppTheme.primaryColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.my_location),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStationDetailCard(BuildContext context) {
    final station = controller.selectedStation.value!;
    final isAdded = controller.tripStops.any((s) => s.chargerId == station.chargerId);
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.fromLTRB(16, 16, 16, isSavedTripMode ? 16 : 120), // Increased bottom margin for footer only if embedded
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark Theme
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             children: [
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       station.name ?? "Unknown Station",
                       style: const TextStyle(
                         fontSize: 16,
                         fontWeight: FontWeight.bold,
                         color: Colors.white, // White text
                       ),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                     const SizedBox(height: 4),
                     Text(
                       station.location?.address ?? "",
                       style: TextStyle(
                         fontSize: 12,
                         color: Colors.grey[400], // Lighter grey
                       ),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ],
                 ),
               ),
               IconButton(
                 icon: const Icon(Icons.close, color: Colors.grey),
                 onPressed: () => controller.deselectStation(),
               ),
             ],
           ),
           Divider(color: Colors.white.withValues(alpha: 0.1)),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               // Status
               Row(
                 children: [
                   Icon(Icons.check_circle, color: Colors.green, size: 16),
                   SizedBox(width: 4),
                   Text("Available", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                 ],
               ),
               // Distance (Mock)
               Text("${station.distance?.toStringAsFixed(1) ?? '--'} kms", style: TextStyle(color: Colors.grey, fontSize: 12)),
             ],
           ),
           const SizedBox(height: 16),
           SizedBox(
             width: double.infinity,
             child: ElevatedButton(
               onPressed: () {
                 if (isAdded) {
                   controller.tripStops.removeWhere((s) => s.chargerId == station.chargerId);
                   Get.snackbar("Removed", "Station removed from trip", colorText: Colors.white, backgroundColor: Colors.red);
                 } else {
                   controller.tripStops.add(station);
                   Get.snackbar("Added", "Station added to trip", colorText: Colors.white, backgroundColor: Colors.green);
                 }
                 controller.deselectStation(); // Close card
               },
               style: ElevatedButton.styleFrom(
                 backgroundColor: isAdded ? Colors.red : Colors.deepOrange,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
               ),
               child: Text(
                 isAdded ? "Remove station" : "Add station",
                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
               ),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildTripItinerarySheet(BuildContext context) {
    return Obx(() {
      final isMinimized = controller.isItineraryMinimized.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: isSavedTripMode ? 0 : 110), // Float above nav bar only if embedded
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Dark Theme
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "via Optimized Route", // Mock
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isMinimized
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white70,
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
                     Divider(color: Colors.white.withValues(alpha: 0.1)),
                     
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
                                  onPressed: controller.clearSearch,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.red, 
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ), 
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // SAVE BUTTON
                            SizedBox(
                                height: 50,
                                width: 50,
                                child: IconButton(
                                   onPressed: controller.currentSavedTripId.value != null 
                                     ? null // Disable if already saved (loaded from saved)
                                     : () => _showSaveTripDialog(context),
                                   icon: Icon(
                                     controller.currentSavedTripId.value != null ? Icons.bookmark : Icons.bookmark_border,
                                     color: Colors.white,
                                   ),
                                   style: IconButton.styleFrom(
                                     backgroundColor: const Color(0xFF333333),
                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                   ),
                                ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    controller.launchGoogleMapsNavigation();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Start",
                                    style: TextStyle(
                                      color: Colors.black,
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
      Get.dialog(
         Dialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
               padding: const EdgeInsets.all(20),
               child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      Text("Save Trip", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                          controller: textController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                              hintText: "Enter trip name",
                              hintStyle: const TextStyle(color: Colors.white30),
                              filled: true,
                              fillColor: Colors.black12,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                          children: [
                              Expanded(child: OutlinedButton(onPressed: () => Get.back(), child: const Text("Cancel", style: TextStyle(color: Colors.white)))),
                              const SizedBox(width: 16),
                              Expanded(child: ElevatedButton(
                                  onPressed: () {
                                      if (textController.text.isNotEmpty) {
                                          Get.back();
                                          controller.saveCurrentTrip(textController.text);
                                      }
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                                  child: const Text("Save", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              )),
                          ]
                      )
                  ],
               ),
            ),
         ),
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
                    color: Colors.white24, // Light line
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white, // White text
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isStop ? Colors.grey[400] : (subtitle.contains("Departure") ? Colors.red[300] : Colors.green[400]), // Colored subtitle
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

  Widget _buildPlanningSheet(BuildContext context) {
    final bool fromSaved = Get.arguments != null && Get.arguments is Map && Get.arguments['fromSaved'] == true;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 20, 16, fromSaved ? 20 : 100), // Increased bottom padding for nav bar only if embedded
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark Card
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
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
            const Text(
              "Plan your next trip",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18, // Reduced size
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tackle your range anxiety with our hassle-free charging experience on your next trip.",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12, // Reduced size
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16), // Reduced spacing

            // Inputs Card
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212), // Darker inner bg
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                                        decoration: const BoxDecoration(
                                          color: Colors.white54,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ValueListenableBuilder<TextEditingValue>(
                                          valueListenable: controller.sourceController,
                                          builder: (context, value, child) {
                                            return Text(
                                              value.text.isEmpty 
                                                  ? "Current Location" 
                                                  : value.text,
                                              style: const TextStyle(
                                                color: Colors.white,
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
                                  // SoC Slider for Departure
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                           Obx(() => Text(
                                            "Departure SoC - ${controller.departureSoC.value.toInt()}%",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          )),
                                          const Icon(Icons.swap_vert, color: Colors.white24, size: 16),
                                        ],
                                      ),
                                      Obx(() => SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 4,
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                          activeTrackColor: _getSoCColor(controller.departureSoC.value),
                                          inactiveTrackColor: Colors.white10,
                                          thumbColor: Colors.white,
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
                          
                          Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                          
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
                                          color: AppTheme.primaryColor, // Highlight color
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
                                                    ? Colors.grey 
                                                    : Colors.white,
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
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Arrival SoC - 0% (approx)",
                                        style: TextStyle(
                                          color: Colors.white70,
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

  Widget _buildSearchLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        automaticallyImplyLeading: true,
        title: Obx(
          () => Text(
            controller.searchMode.value == 'explore'
                ? "Search Location"
                : "Set a Trip",
            style: const TextStyle(
              color: Colors.white,
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
              color: const Color(0xFF1E1E1E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
                              hint: "Current Location",
                              icon: Icons.my_location,
                              iconColor: Colors.blue,
                              isSource: true,
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
                        style: const TextStyle(color: Colors.white)));
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
                    color: Colors.white.withOpacity(0.1),
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
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        mainText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        secondaryText,
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                          // Handle selection
                          controller.onPlaceSelected(placeId, description);
                          // If we are not embedded (i.e. called from Trip Page), we might want to pop back
                          // But onPlaceSelected usually navigates or updates state.
                          // If logic expects to stay on search view, fine.
                          // Usually it navigates to RouteView.
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
                      const Text(
                        "Location not found",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Please try a different address or locate on\nthe map",
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[400]),
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
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, color: Colors.white),
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
              color: const Color(0xFF1E1E1E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.my_location,
                          color: Colors.white70,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Current Location",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                    height: 24, width: 1, color: Colors.white.withOpacity(0.2)),
                Expanded(
                  child: InkWell(
                    onTap: () => Get.to(
                      () => const LocateOnMapView(),
                      transition: Transition.rightToLeft,
                      duration: const Duration(milliseconds: 300),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          color: Colors.white70,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Locate on map",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: Colors.white,
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
          style: const TextStyle(fontSize: 16, color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600]),
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
