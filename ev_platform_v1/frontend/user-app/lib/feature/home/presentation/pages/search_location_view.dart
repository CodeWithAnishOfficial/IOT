import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/feature/home/presentation/controllers/home_controller.dart';

class SearchLocationView extends GetView<HomeController> {
  const SearchLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    // Request focus after the frame is built to avoid transition stutter/crash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.searchResults.isEmpty) {
        // Optionally request focus here if needed, but safe to keep off by default
        // or handle with a focus node
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Search",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              autofocus: false,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search for charging station...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller.searchController,
                  builder: (context, value, child) {
                    return value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              controller.searchController.clear();
                              controller.onSearchChanged('');
                            },
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isSearching.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.searchError.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.grey[400], size: 48),
                      const SizedBox(height: 16),
                      Text(
                        controller.searchError.value,
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      if (controller.searchError.value.contains("timeout") || 
                          controller.searchError.value.contains("failed"))
                        TextButton.icon(
                          onPressed: () => controller.searchPlaces(controller.searchController.text),
                          icon: const Icon(Icons.refresh),
                          label: const Text("Retry"),
                        )
                    ],
                  ),
                );
              }

              if (controller.searchResults.isEmpty &&
                  controller.searchController.text.isNotEmpty) {
                return const Center(
                  child: Text(
                    "No results found",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              // Default View: Current Location + Recent Searches
              if (controller.searchResults.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    // Current Location Option
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.my_location,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        "Use my current location",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        "Search nearby stations",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      onTap: () {
                         Get.back();
                         controller.recenterMap();
                      },
                    ),
                    
                    // Recent Searches Section
                    Obx(() {
                      if (controller.recentSearches.isEmpty) return const SizedBox.shrink();
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
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
                            return Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: const Icon(Icons.history, color: Colors.grey, size: 22),
                                  title: Text(
                                    recent['description'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(Icons.north_west, size: 16, color: Colors.grey),
                                  onTap: () => controller.onPlaceSelected(
                                    recent['placeId']!,
                                    recent['description']!,
                                  ),
                                ),
                                const Divider(height: 1, thickness: 0.5, indent: 56, endIndent: 16),
                              ],
                            );
                          }).toList(),
                        ],
                      );
                    }),
                  ],
                );
              }

              // Search Results List
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: controller.searchResults.length,
                separatorBuilder: (context, index) =>
                    // Thinner separator (0.5 thickness)
                    Divider(height: 1, thickness: 0.5, indent: 72, endIndent: 16, color: Colors.grey[200]),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Colors.black87,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      mainText,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    subtitle: Text(
                      secondaryText,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () =>
                        controller.onPlaceSelected(placeId, description),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
