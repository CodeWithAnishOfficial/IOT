import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/app/modules/vehicles/controllers/vehicles_controller.dart';

class VehiclesView extends GetView<VehiclesController> {
  const VehiclesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('My Vehicles')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVehicleDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.vehicles.isEmpty) {
          return Center(
            child: Text(
              'No vehicles added yet.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodySmall?.color
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: controller.vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = controller.vehicles[index];
            return Card(
              color: theme.cardColor,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(
                  Icons.directions_car,
                  size: 40,
                  color: theme.primaryColor,
                ),
                title: Text(
                  '${vehicle.make} ${vehicle.modelName} (${vehicle.year})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Type: ${vehicle.connectorType}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (vehicle.plateNo != null)
                      Text(
                        'Plate: ${vehicle.plateNo}',
                        style: theme.textTheme.bodyMedium,
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, vehicle.id),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showAddVehicleDialog(BuildContext context) {
    final theme = Theme.of(context);
    final makeController = TextEditingController();
    final modelController = TextEditingController();
    final yearController = TextEditingController();
    final plateController = TextEditingController();
    final connectorType = 'Type2'.obs;

    Get.defaultDialog(
      title: 'Add Vehicle',
      titleStyle: theme.textTheme.titleLarge,
      backgroundColor: theme.cardColor,
      content: Column(
        children: [
          TextField(
            controller: makeController,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Make',
              labelStyle: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: modelController,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Model',
              labelStyle: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: yearController,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Year',
              labelStyle: theme.textTheme.bodyMedium,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: plateController,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Plate No (Optional)',
              labelStyle: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => DropdownButton<String>(
              value: connectorType.value,
              dropdownColor: theme.cardColor,
              style: theme.textTheme.bodyMedium,
              items:
                  [
                    'Type2',
                    'CCS2',
                    'Chademo',
                    'GB/T',
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (val) => connectorType.value = val!,
              isExpanded: true,
            ),
          ),
        ],
      ),
      textConfirm: 'Add',
      textCancel: 'Cancel',
      confirmTextColor: theme.colorScheme.onPrimary,
      cancelTextColor: theme.colorScheme.onSurface,
      buttonColor: theme.primaryColor,
      onConfirm: () {
        if (makeController.text.isEmpty ||
            modelController.text.isEmpty ||
            yearController.text.isEmpty) {
          Get.snackbar(
            'Error',
            'Please fill required fields',
            colorText: Colors.white,
            backgroundColor: Colors.red,
          );
          return;
        }
        controller.addVehicle({
          'make': makeController.text,
          'modelName': modelController.text,
          'year': int.parse(yearController.text),
          'plate_no': plateController.text,
          'connector_type': connectorType.value,
          'is_default': false,
        });
        Get.back(); // Close dialog on success? usually controller handles logic but here it's inline
      },
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    final theme = Theme.of(context);
    Get.defaultDialog(
      title: 'Delete Vehicle',
      titleStyle: theme.textTheme.titleLarge,
      middleText: 'Are you sure you want to delete this vehicle?',
      middleTextStyle: theme.textTheme.bodyMedium,
      backgroundColor: theme.cardColor,
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      cancelTextColor: theme.colorScheme.onSurface,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back(); // Close dialog
        controller.deleteVehicle(id);
      },
    );
  }
}
