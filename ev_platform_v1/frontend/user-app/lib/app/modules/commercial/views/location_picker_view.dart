import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/app/modules/commercial/controllers/commercial_controller.dart';
import 'package:user_app/core/theme/app_colors.dart';

class LocationPickerView extends GetView<CommercialController> {
  const LocationPickerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final TextEditingController searchController = TextEditingController();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Search Location',
          style: GoogleFonts.poppins(
            color: theme.textTheme.titleLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search for a place...',
                  icon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      searchController.clear();
                      controller.searchResults.clear();
                    },
                  ),
                ),
                onChanged: (val) {
                  // Debounce could be added here
                  if (val.length > 2) {
                     controller.searchPlaces(val);
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isSearching.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.searchResults.isEmpty) {
                return Center(
                  child: Text(
                    'No results found',
                    style: GoogleFonts.poppins(color: theme.disabledColor),
                  ),
                );
              }

              return ListView.separated(
                itemCount: controller.searchResults.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: theme.dividerColor.withOpacity(0.1),
                ),
                itemBuilder: (context, index) {
                  final result = controller.searchResults[index];
                  final description = result['description'] ?? '';
                  final mainText = result['structured_formatting']?['main_text'] ?? description;
                  final secondaryText = result['structured_formatting']?['secondary_text'] ?? '';
                  final placeId = result['place_id'];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    title: Text(
                      mainText,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: secondaryText.isNotEmpty
                        ? Text(
                            secondaryText,
                            style: GoogleFonts.poppins(
                              color: theme.disabledColor,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    onTap: () async {
                      final details = await controller.getPlaceDetails(placeId);
                      if (details != null) {
                        Get.back(result: details);
                      }
                    },
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
