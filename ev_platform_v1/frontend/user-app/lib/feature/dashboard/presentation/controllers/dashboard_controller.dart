import 'package:get/get.dart';
import 'package:user_app/feature/home/presentation/controllers/home_controller.dart';
import 'package:user_app/feature/reservation/presentation/controllers/reservation_controller.dart';

class DashboardController extends GetxController {
  final tabIndex = 0.obs;

  void changeTabIndex(int index) {
    tabIndex.value = index;

    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();

      if (index == 1) {
        // If coming from a saved trip (ID is set), clear state for fresh planning
        if (homeController.currentSavedTripId.value != null) {
          homeController.clearSearch();
        }
        homeController.searchMode.value = 'trip';
      } else if (index == 0) {
        homeController.searchMode.value = 'explore';
        // Refresh Map Stations silently to update status
        if (homeController.currentLocation.value != null) {
            homeController.fetchNearbyStations(
              lat: homeController.currentLocation.value!.latitude,
              lng: homeController.currentLocation.value!.longitude,
              silent: true,
            );
        }
      }
    }

    // Refresh Reservations when switching to Tab 2
    if (index == 2) {
      if (Get.isRegistered<ReservationController>()) {
        final resController = Get.find<ReservationController>();
        resController.fetchStations(); // Refresh stations list
        resController.fetchMyReservations(); // Refresh user reservations
      }
      // Note: If controller is not registered, ReservationView will Get.put it,
      // which triggers onInit, so data will be fetched automatically.
    }
  }
}
