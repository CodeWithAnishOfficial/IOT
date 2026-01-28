import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_app/app/modules/trip/controllers/trip_controller.dart';
import 'package:user_app/app/modules/trip/views/trip_search_view.dart';
import 'package:user_app/core/theme/app_colors.dart';

class TripView extends GetView<TripController> {
  const TripView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Map
          Obx(() => GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(20.5937, 78.9629), // India
              zoom: 5,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: controller.markers.toSet(),
            polylines: controller.polylines.toSet(),
            onMapCreated: controller.onMapCreated,
            onTap: (_) => controller.deselectStation(),
          )),

          // 2. Back Button
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: isDark ? Colors.black54 : Colors.white,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
                onPressed: () => Get.back(),
              ),
            ),
          ),

          // 3. Inputs & Itinerary Sheet
          // We can use a DraggableScrollableSheet or just a Positioned widget
          // For now, let's use a fixed Positioned bottom sheet that can expand?
          // Or just replicate the behavior in SearchLocationView
          
          Positioned(
             left: 0,
             right: 0,
             bottom: 0,
             child: Container(
               constraints: BoxConstraints(maxHeight: Get.height * 0.8),
               decoration: BoxDecoration(
                 color: theme.cardTheme.color,
                 borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.1),
                     blurRadius: 20,
                     offset: const Offset(0, -5),
                   ),
                 ],
               ),
               child: SingleChildScrollView(
                 child: Obx(() {
                    if (controller.isSavedTripMode.value) {
                      return _buildSavedTripDetails(context);
                    }
                    return _buildPlannerForm(context);
                 }),
               ),
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedTripDetails(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        // Drag Handle
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? Colors.white24 : Colors.black12,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Trip Details", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => controller.isSavedTripMode.value = false, // Switch to edit mode
                tooltip: "Edit Trip",
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // Itinerary List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Start
              _buildItineraryItem(
                context, 
                "Start Location", 
                controller.sourceController.text, 
                Icons.my_location, 
                Colors.blue,
                isStart: true
              ),

              // Stops
              ...controller.tripStops.asMap().entries.map((entry) {
                return _buildItineraryItem(
                  context,
                  "Stop ${entry.key + 1}",
                  entry.value.name ?? entry.value.location?.address ?? "Stop",
                  Icons.ev_station,
                  Colors.purple,
                  isStop: true,
                );
              }),

              // Destination
              _buildItineraryItem(
                context, 
                "Destination", 
                controller.destinationController.text, 
                Icons.location_on, 
                Colors.red,
                isEnd: true
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    controller.cancelTrip();
                    Get.back();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.dividerColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text("Close", style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Start Navigation Stub
                    Get.snackbar("Navigation", "Starting navigation...");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Start Navigation", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildItineraryItem(BuildContext context, String label, String address, IconData icon, Color color, {bool isStart = false, bool isEnd = false, bool isStop = false}) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
           Column(
             children: [
                Container(
                   width: 36,
                   height: 36,
                   decoration: BoxDecoration(
                     color: color.withOpacity(0.1), 
                     shape: BoxShape.circle
                   ),
                   child: Icon(icon, color: color, size: 18),
                ),
                if (!isEnd) 
                   Expanded(
                     child: Container(
                       width: 2, 
                       color: theme.dividerColor.withOpacity(0.5), 
                       margin: const EdgeInsets.symmetric(vertical: 4)
                     )
                   ),
             ],
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Padding(
               padding: const EdgeInsets.only(bottom: 24, top: 8), 
               child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(label, style: TextStyle(color: theme.disabledColor, fontSize: 12, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 4),
                     Text(
                       address.isNotEmpty ? address : "Select Location", 
                       style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14), 
                       maxLines: 2, 
                       overflow: TextOverflow.ellipsis
                     ),
                  ],
               ),
             ),
           )
        ],
      ),
    );
  }

  Widget _buildPlannerForm(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                      const SizedBox(height: 16),
                      // Drag Handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Title
                      Text("Trip Planner", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      
                      const SizedBox(height: 16),

                      // Inputs
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Source
                            _buildInput(
                              context, 
                              controller.sourceController, 
                              "Start Location", 
                              Icons.my_location, 
                              Colors.blue,
                              onTap: () {
                                controller.activeField.value = 'source';
                                Get.to(() => const TripSearchView());
                              }
                            ),
                            const SizedBox(height: 12),
                            // Destination
                            _buildInput(
                              context, 
                              controller.destinationController, 
                              "Destination", 
                              Icons.location_on, 
                              Colors.red,
                              onTap: () {
                                 controller.activeField.value = 'destination';
                                 Get.to(() => const TripSearchView());
                              }
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  controller.cancelTrip();
                                  // Get.back(); // Optional? User said "Cancel must reset to intact trip", implies staying on screen? 
                                  // Or "Cancel must reset to initial state".
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text("Reset", style: TextStyle(color: Colors.red)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => controller.planTrip(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text("Plan Trip", style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                   ],
                 );
  }

  Widget _buildInput(BuildContext context, TextEditingController controller, String hint, IconData icon, Color color, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      readOnly: false, // Allow typing or make readonly if pure picker
      onTap: onTap,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: color),
        hintText: hint,
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
