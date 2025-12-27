import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/feature/more/presentation/pages/manage/presentation/pages/vehicle/presentation/controllers/vehicles_controller.dart';

class VehiclesView extends GetView<VehiclesController> {
  const VehiclesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          return const Center(child: Text('No vehicles added yet.'));
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
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${vehicle.connectorType}'),
                    if (vehicle.plateNo != null)
                      Text('Plate: ${vehicle.plateNo}'),
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
      content: Column(
        children: [
          TextField(
            controller: makeController,
            decoration: const InputDecoration(labelText: 'Make'),
          ),
          TextField(
            controller: modelController,
            decoration: const InputDecoration(labelText: 'Model'),
          ),
          TextField(
            controller: yearController,
            decoration: const InputDecoration(labelText: 'Year'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: plateController,
            decoration: const InputDecoration(labelText: 'Plate No (Optional)'),
          ),
          const SizedBox(height: 16),
          Obx(
            () => DropdownButton<String>(
              value: connectorType.value,
              items: [
                'Type2',
                'CCS2',
                'Chademo',
                'GB/T',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => connectorType.value = val!,
              isExpanded: true,
            ),
          ),
        ],
      ),
      textConfirm: 'Add',
      textCancel: 'Cancel',
      onConfirm: () {
        if (makeController.text.isEmpty ||
            modelController.text.isEmpty ||
            yearController.text.isEmpty) {
          Get.snackbar('Error', 'Please fill required fields');
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
      },
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    Get.defaultDialog(
      title: 'Delete Vehicle',
      middleText: 'Are you sure you want to delete this vehicle?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back(); // Close dialog
        controller.deleteVehicle(id);
      },
    );
  }
}
