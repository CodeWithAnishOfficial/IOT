import 'package:get/get.dart';
import 'package:user_app/core/network/api_provider.dart';
import 'package:user_app/feature/more/presentation/pages/manage/presentation/pages/vehicle/domain/models/vehicle.dart';

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
      Get.snackbar('Error', 'Failed to fetch vehicles');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addVehicle(Map<String, dynamic> vehicleData) async {
    try {
      isLoading.value = true;
      await _apiProvider.post('/vehicles/add', vehicleData);
      Get.back(); // Close dialog or screen
      fetchVehicles(); // Refresh list
      Get.snackbar('Success', 'Vehicle added');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add vehicle: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      isLoading.value = true;
      await _apiProvider.delete('/vehicles/delete/$id');
      fetchVehicles(); // Refresh list
      Get.snackbar('Success', 'Vehicle deleted');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete vehicle: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
