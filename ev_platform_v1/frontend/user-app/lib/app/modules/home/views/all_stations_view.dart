import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/app/modules/home/controllers/all_stations_controller.dart';
import 'package:user_app/app/modules/home/domain/models/charger.dart';
import 'package:user_app/app/modules/home/widgets/station_card_skeleton.dart';
import 'package:user_app/core/theme/app_colors.dart';

class AllStationsView extends StatelessWidget {
  const AllStationsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Put the controller if not already
    final controller = Get.put(AllStationsController());
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color;
    final textColor = theme.colorScheme.onSurface;
    final hintColor = isDark ? Colors.grey : Colors.grey[600];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Expanded(
              child: Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: hintColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller.searchController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: "Search Station...",
                          hintStyle: TextStyle(color: hintColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(bottom: 5),
                        ),
                      ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller.searchController,
                      builder: (context, value, child) {
                        if (value.text.isEmpty) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () {
                            controller.searchController.clear();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Icon(
                              Icons.close,
                              color: hintColor,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                    Icon(Icons.tune, color: hintColor), 
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
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
                      color: isSelected ? Colors.black : textColor,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    selected: isSelected,
                    onSelected: (_) => controller.updateFilter(filter),
                    selectedColor: Colors.white,
                    backgroundColor: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white10 : Colors.black12),
                      ),
                    ),
                  );
                });
              },
            ),
          ),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, __) => const StationCardSkeleton(),
                );
              }

              // Search Results (Places)
              if (controller.isSearchingLocation.value) {
                 if (controller.searchResults.isEmpty) {
                   return Center(
                     child: Text(
                       "No locations found",
                       style: GoogleFonts.poppins(
                         color: isDark ? Colors.white54 : Colors.black54,
                       ),
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
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
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
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        title: Text(
                          mainText,
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          secondaryText,
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          controller.onPlaceSelected(
                            placeId,
                            description,
                          );
                        },
                      );
                    },
                  );
              }

              if (controller.filteredStations.isEmpty) {
                return Center(
                  child: Text(
                    "No stations found",
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                );
              }

              return ListView.separated(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: controller.filteredStations.length + (controller.isLoadMoreRunning.value ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  if (index == controller.filteredStations.length) {
                     return const StationCardSkeleton();
                  }
                  final station = controller.filteredStations[index];
                  return _buildStationCard(
                    context,
                    station,
                    theme,
                    isDark,
                    textColor,
                    cardColor,
                    index,
                    controller,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStationCard(
    BuildContext context,
    Charger station,
    ThemeData theme,
    bool isDark,
    Color textColor,
    Color? cardColor,
    int index,
    AllStationsController controller,
  ) {
    bool isAvailable = station.status.toLowerCase() == 'online';
    final isImageRight = index % 2 != 0;

    return GestureDetector(
      onTap: () {
        controller.navigateToStationDetails(station);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!isImageRight) _buildCardImage(),
            if (!isImageRight) const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name ?? "Unknown Station",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    station.location?.address ?? "Unknown",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isAvailable ? "Open 24 Hours" : "Closed",
                            style: GoogleFonts.poppins(
                              color: isAvailable ? Colors.green : Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Spacer(),
                      Text(
                        "${station.distance?.toStringAsFixed(1) ?? '--'} km",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      Text(
                        "4.8",
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (isImageRight) const SizedBox(width: 16),
            if (isImageRight) _buildCardImage(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          "assets/images/station_detaile_ev_station_img.png",
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.ev_station, size: 40, color: Colors.grey),
        ),
      ),
    );
  }
}
