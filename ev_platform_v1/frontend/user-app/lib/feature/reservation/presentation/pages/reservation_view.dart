import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/feature/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:user_app/feature/home/domain/models/charger.dart';
import 'package:user_app/feature/reservation/presentation/controllers/reservation_controller.dart';
import 'package:user_app/feature/reservation/presentation/pages/booking_view.dart';
import 'package:user_app/utils/theme/themes.dart';

class ReservationView extends StatelessWidget {
  const ReservationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReservationController());

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller.searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Search Station...",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(bottom: 5),
                        ),
                      ),
                    ),
                    // Clear Button
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller.searchController,
                      builder: (context, value, child) {
                        if (value.text.isEmpty) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () {
                             controller.searchController.clear();
                             // Ensure focus is removed if needed, or kept
                             // controller.onClearSearch(); // If method exists
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(Icons.close, color: Colors.grey, size: 20),
                          ),
                        );
                      },
                    ),
                    const Icon(Icons.tune, color: Colors.grey), // Filter icon
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Toggle Tabs
          Container(
            margin: const EdgeInsets.all(16),
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white10),
            ),
            child: Obx(() => Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.viewMode.value = 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: controller.viewMode.value == 0 ? AppTheme.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "My Reservations",
                        style: GoogleFonts.poppins(
                          color: controller.viewMode.value == 0 ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.viewMode.value = 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: controller.viewMode.value == 1 ? AppTheme.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Book New",
                        style: GoogleFonts.poppins(
                          color: controller.viewMode.value == 1 ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )),
          ),

          Expanded(
            child: Obx(() {
              if (controller.viewMode.value == 0) {
                // My Reservations List
                if (controller.myReservations.isEmpty) {
                   return Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.calendar_today, size: 64, color: Colors.white12),
                         SizedBox(height: 16),
                         Text(
                           "No reservations found",
                           style: GoogleFonts.poppins(color: Colors.white54),
                         ),
                       ],
                     ),
                   );
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.myReservations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final reservation = controller.myReservations[index];
                    return GestureDetector(
                      onTap: () => controller.onReservationClick(reservation),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.ev_station, color: Colors.blue),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Charger ${reservation['charger_id']}",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Connector ${reservation['connector_id']} • ${reservation['status']}",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                );

              } else {
                // Book New (Existing Search UI)
                return Column(
                  children: [
                    // Filter Chips (Existing)
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final filter = controller.filters[index];
                          return Obx(() {
                            final isSelected = controller.selectedFilter.value == filter;
                            return ChoiceChip(
                              label: Text(filter),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              selected: isSelected,
                              onSelected: (_) => controller.updateFilter(filter),
                              selectedColor: Colors.white,
                              backgroundColor: const Color(0xFF1E1E1E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? Colors.white : Colors.white10,
                                ),
                              ),
                            );
                          });
                        },
                      ),
                    ),

                    // Station List or Search Results (Existing)
                    Expanded(
                      child: Obx(() {
                        if (controller.isLoading.value) {
                          return const Center(
                            child: CircularProgressIndicator(color: AppTheme.primaryColor),
                          );
                        }

                        // Show Search Results
                        if (controller.isSearchingLocation.value) {
                          if (controller.searchResults.isEmpty) {
                             return Center(
                               child: Text(
                                 "No locations found",
                                 style: GoogleFonts.poppins(color: Colors.white54),
                               ),
                             );
                          }
                          
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
                              final mainText = result['structured_formatting']?['main_text'] ?? description.split(',')[0];
                              final secondaryText = result['structured_formatting']?['secondary_text'] ?? description;
                              final placeId = result['place_id'] ?? '';

                              return ListTile(
                                leading: const Icon(Icons.location_on_outlined, color: Colors.white70),
                                title: Text(
                                  mainText, 
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  secondaryText,
                                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  controller.onPlaceSelected(placeId, description);
                                },
                              );
                            },
                          );
                        }

                        if (controller.filteredStations.isEmpty) {
                          return Center(
                            child: Text(
                              "No stations found",
                              style: GoogleFonts.poppins(color: Colors.white54),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: controller.filteredStations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final station = controller.filteredStations[index];
                            return _buildStationCard(context, station);
                          },
                        );
                      }),
                    ),
                  ],
                );
              }
            }),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 110), // Raised to clear custom bottom nav
        child: FloatingActionButton.extended(
          onPressed: () {
             if (Get.isRegistered<DashboardController>()) {
                Get.find<DashboardController>().changeTabIndex(0);
             }
             Get.back();
          },
          backgroundColor: AppTheme.primaryColor, // Use Theme Color
          icon: const Icon(Icons.map, color: Colors.black), // Black icon for contrast on fluorescent green
          label: Text("Map", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  Widget _buildStationCard(BuildContext context, Charger station) {
    bool isAvailable = station.status.toLowerCase() == 'online';
    bool hasDC = station.connectors.any((c) => (c.type?.contains('CCS') ?? false) || (c.type?.contains('DC') ?? false));
    
    return GestureDetector(
      onTap: () {
        Get.to(() => BookingView(station: station));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Dark Card
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    station.name ?? "Unknown Station",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        "4.8",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.green, size: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              station.location?.address ?? "Unknown",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
             Text(
              "${station.distance?.toStringAsFixed(1) ?? '1.2'} km away",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Available Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAvailable 
                        ? Colors.green.withOpacity(0.15) 
                        : Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAvailable ? Colors.green : Colors.red,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isAvailable ? "Available" : "Busy",
                        style: GoogleFonts.poppins(
                          color: isAvailable ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isAvailable ? Icons.check_circle : Icons.cancel,
                        color: isAvailable ? Colors.green : Colors.red,
                        size: 14,
                      ),
                    ],
                  ),
                ),
                
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasDC ? "DC" : "AC",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
