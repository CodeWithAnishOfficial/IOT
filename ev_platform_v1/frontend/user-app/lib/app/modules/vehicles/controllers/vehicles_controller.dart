import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/core/network/api_provider.dart';
import 'package:user_app/app/modules/vehicles/domain/models/vehicle.dart';

class VehiclesController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  final vehicles = <Vehicle>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchVehicles();
  }

  Future<void> fetchVehicles() async {
    try {
      isLoading.value = true;
      final response = await _apiProvider.get('/vehicles/list');
      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        vehicles.value = data.map((e) => Vehicle.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching vehicles: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addVehicle(Map<String, dynamic> vehicleData) async {
    try {
      isLoading.value = true;
      final response = await _apiProvider.post('/vehicles/add', vehicleData);
      
      // Check for backend error response structure if not caught by ApiProvider
      if (response is Map && response['error'] == true) {
         throw Exception(response['message'] ?? 'Unknown error');
      }

      fetchVehicles(); // Refresh list
      
      Get.snackbar(
        'Success', 
        'Vehicle added successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      String errorMessage = 'Failed to add vehicle';
      if (e is ApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString().replaceAll('Exception:', '').trim();
      }
      
      Get.snackbar(
        'Error', 
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      // Re-throw so the view knows not to close if needed (though view closes currently)
      // Actually, since View calls this and then closes, we might want to handle this differently.
      // But the View currently awaits this. If we catch here, the View continues.
      // We should rethrow or let the view handle logic. 
      // For now, let's keep it here but we might need to change View logic if we want to prevent closing on error.
      rethrow; 
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      isLoading.value = true;
      await _apiProvider.delete('/vehicles/delete/$id');
      fetchVehicles(); // Refresh list
      Get.snackbar(
        'Success', 
        'Vehicle deleted',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Error', 
        'Failed to delete vehicle: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
