import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_app/feature/home/presentation/controllers/home_controller.dart';

class LocateOnMapView extends GetView<HomeController> {
  const LocateOnMapView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initial camera position - use current location or default
    final initialPos = controller.currentLocation.value != null
        ? LatLng(controller.currentLocation.value!.latitude,
            controller.currentLocation.value!.longitude)
        : const LatLng(20.5937, 78.9629); // India fallback

    // Local variable to track center - but better to rely on controller for address update
    // We just need to know the center when Confirm is clicked. 
    // Actually, the controller updates pickerAddress on idle, but we need the LatLng too.
    // Let's store the current center in a local variable or use the map controller.
    // Since we are using GetView, we can use a local Rx variable or just pass the map camera target.
    
    final Rx<LatLng> currentCenter = initialPos.obs;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPos,
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onCameraMove: (position) {
              currentCenter.value = position.target;
            },
            onCameraIdle: () {
              controller.updatePickerAddress(currentCenter.value);
            },
            onMapCreated: (GoogleMapController mapController) {
               // If we want to animate to user location on start
            },
          ),
          
          // Center Pin
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35), // Adjust for pin anchor
              child: Icon(
                Icons.location_on,
                size: 45,
                color: Colors.black,
              ),
            ),
          ),
          // Small dot at actual center for precision
          Center(
             child: Container(
               width: 4, 
               height: 4, 
               decoration: const BoxDecoration(
                 color: Colors.black, 
                 shape: BoxShape.circle
               )
             )
          ),

          // Top Address Card
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                   GestureDetector(
                     onTap: () => Get.back(),
                     child: const Icon(Icons.arrow_back, color: Colors.black),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         // Green dot + Text?
                         Row(
                           children: [
                             Container(
                               width: 8, height: 8,
                               decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                             ),
                             const SizedBox(width: 8),
                             Expanded(
                               child: Obx(() => Text(
                                 controller.pickerAddress.value,
                                 style: const TextStyle(
                                   fontWeight: FontWeight.w500,
                                   fontSize: 16,
                                 ),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                               )),
                             ),
                           ],
                         ),
                         const SizedBox(height: 4),
                         Obx(() => controller.isPickerLoading.value 
                           ? const LinearProgressIndicator(minHeight: 2)
                           : const SizedBox(height: 2)
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
          ),

          // Bottom Confirm Button
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  controller.confirmPickerLocation(
                    currentCenter.value, 
                    controller.pickerAddress.value
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Confirm Location",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
