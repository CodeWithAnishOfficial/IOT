import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/app/modules/home/controllers/home_controller.dart';
import 'package:user_app/core/theme/app_theme.dart';
import 'package:user_app/core/theme/app_colors.dart';

class SavedTripsView extends StatelessWidget {
  const SavedTripsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    
    // Fetch trips when view opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchSavedTrips();
    });

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text("Saved Trips", style: GoogleFonts.poppins(color: theme.textTheme.titleLarge?.color)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.savedTrips.isEmpty) {
          return Center(
            child: Text(
              "No saved trips found",
              style: GoogleFonts.poppins(color: theme.hintColor),
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
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
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
                           color: theme.textTheme.bodyLarge?.color,
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
                             icon: const Icon(Icons.play_circle_fill, color: AppColors.primary, size: 32),
                             onPressed: () => controller.loadSavedTrip(trip),
                           ),
                         ],
                       ),
                     ],
                   ),
                   Divider(color: theme.dividerColor),
                   _buildRow(context, Icons.circle, Colors.blue, trip.source.address),
                   Padding(
                     padding: const EdgeInsets.only(left: 11),
                     child: SizedBox(
                       height: 12, 
                       child: VerticalDivider(color: theme.dividerColor, width: 2)
                     ),
                   ),
                   _buildRow(context, Icons.location_on, Colors.red, trip.destination.address),
                   if (trip.stops.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        "${trip.stops.length} Stops",
                        style: GoogleFonts.poppins(color: theme.hintColor, fontSize: 12),
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

  Widget _buildRow(BuildContext context, IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 14),
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
      backgroundColor: Theme.of(context).cardTheme.color,
      titleStyle: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
      middleTextStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      onConfirm: () {
        Get.back(); // Close dialog
        controller.deleteSavedTrip(tripId);
      },
    );
  }
}
