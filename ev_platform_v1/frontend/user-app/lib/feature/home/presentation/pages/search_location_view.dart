import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/feature/home/presentation/controllers/home_controller.dart';
import 'package:user_app/feature/home/presentation/pages/locate_on_map_view.dart';

class SearchLocationView extends GetView<HomeController> {
  const SearchLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
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
                      onTap: () =>
                          controller.onPlaceSelected(placeId, description),
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
