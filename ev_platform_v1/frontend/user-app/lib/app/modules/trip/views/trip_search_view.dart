import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/app/modules/trip/controllers/trip_controller.dart';
import 'package:user_app/core/theme/app_colors.dart';

class TripSearchView extends GetView<TripController> {
  const TripSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
        title: TextField(
          autofocus: true,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: "Search location...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.hintColor),
          ),
          onChanged: controller.onSearchChanged,
        ),
      ),
      body: Obx(() {
        if (controller.isSearching.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.searchError.isNotEmpty) {
           return Center(child: Text(controller.searchError.value));
        }

        if (controller.searchResults.isEmpty) {
           return Center(child: Text("Start typing to search", style: TextStyle(color: theme.disabledColor)));
        }

        return ListView.separated(
          itemCount: controller.searchResults.length,
          separatorBuilder: (context, index) => Divider(color: theme.dividerColor),
          itemBuilder: (context, index) {
            final item = controller.searchResults[index];
            final mainText = item['structured_formatting']['main_text'] ?? '';
            final secondaryText = item['structured_formatting']['secondary_text'] ?? '';
            
            return ListTile(
              leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
              title: Text(mainText, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
              subtitle: Text(secondaryText, style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
              onTap: () {
                 controller.onPlaceSelected(item['place_id'], item['description']);
                 Get.back(); // Close picker
              },
            );
          },
        );
      }),
    );
  }
}
