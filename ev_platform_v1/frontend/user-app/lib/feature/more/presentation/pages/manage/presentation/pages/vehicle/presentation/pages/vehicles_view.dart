import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/feature/more/presentation/pages/manage/presentation/pages/vehicle/presentation/controllers/vehicles_controller.dart';

class VehiclesView extends GetView<VehiclesController> {
  const VehiclesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
          return const Center(
            child: Text(
              'No vehicles added yet.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        return ListView.builder(
          itemCount: controller.vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = controller.vehicles[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.directions_car,
                  size: 40,
                  color: Colors.blue,
                ),
                title: Text(
                  '${vehicle.make} ${vehicle.modelName} (${vehicle.year})',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Type: ${vehicle.connectorType}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (vehicle.plateNo != null)
                      Text(
                        'Plate: ${vehicle.plateNo}',
                        style: const TextStyle(color: Colors.white70),
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
    final makeController = TextEditingController();
    final modelController = TextEditingController();
    final yearController = TextEditingController();
    final plateController = TextEditingController();
    final connectorType = 'Type2'.obs;

    Get.defaultDialog(
      title: 'Add Vehicle',
      titleStyle: const TextStyle(color: Colors.white),
      backgroundColor: const Color(0xFF1E1E1E),
      content: Column(
        children: [
          TextField(
            controller: makeController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Make',
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: modelController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Model',
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: yearController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Year',
              labelStyle: TextStyle(color: Colors.white70),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: plateController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Plate No (Optional)',
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => DropdownButton<String>(
              value: connectorType.value,
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(color: Colors.white),
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
      confirmTextColor: Colors.black,
      cancelTextColor: Colors.white,
      buttonColor: Theme.of(context).primaryColor,
      onConfirm: () {
        if (makeController.text.isEmpty ||
            modelController.text.isEmpty ||
            yearController.text.isEmpty) {
          Get.snackbar(
            'Error',
            'Please fill required fields',
            colorText: Colors.white,
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
    Get.defaultDialog(
      title: 'Delete Vehicle',
      titleStyle: const TextStyle(color: Colors.white),
      middleText: 'Are you sure you want to delete this vehicle?',
      middleTextStyle: const TextStyle(color: Colors.white70),
      backgroundColor: const Color(0xFF1E1E1E),
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      cancelTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back(); // Close dialog
        controller.deleteVehicle(id);
      },
    );
  }
}
