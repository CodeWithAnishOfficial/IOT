import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/feature/home/presentation/controllers/home_controller.dart';
import 'package:user_app/utils/theme/themes.dart';

class SavedTripsView extends StatelessWidget {
  const SavedTripsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    
    // Fetch trips when view opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchSavedTrips();
    });

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: Text("Saved Trips", style: GoogleFonts.poppins(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.savedTrips.isEmpty) {
          return Center(
            child: Text(
              "No saved trips found",
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.savedTrips.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final trip = controller.savedTrips[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(
                         trip.name,
                         style: GoogleFonts.poppins(
                           color: Colors.white,
                           fontSize: 16,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       Row(
                         children: [
                           IconButton(
                             icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                             onPressed: () => _confirmDelete(context, controller, trip.id),
                           ),
                           IconButton(
                             icon: const Icon(Icons.play_circle_fill, color: AppTheme.primaryColor, size: 32),
                             onPressed: () => controller.loadSavedTrip(trip),
                           ),
                         ],
                       ),
                     ],
                   ),
                   const Divider(color: Colors.white10),
                   _buildRow(Icons.circle, Colors.blue, trip.source.address),
                   const Padding(
                     padding: EdgeInsets.only(left: 11),
                     child: SizedBox(
                       height: 12, 
                       child: VerticalDivider(color: Colors.white24, width: 2)
                     ),
                   ),
                   _buildRow(Icons.location_on, Colors.red, trip.destination.address),
                   if (trip.stops.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        "${trip.stops.length} Stops",
                        style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                      ),
                   ]
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, HomeController controller, String tripId) {
    Get.defaultDialog(
      title: "Delete Trip",
      middleText: "Are you sure you want to delete this saved trip?",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back(); // Close dialog
        controller.deleteSavedTrip(tripId);
      },
    );
  }
}
