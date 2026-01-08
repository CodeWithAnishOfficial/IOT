import 'package:get/get.dart';
import 'package:user_app/feature/home/presentation/controllers/home_controller.dart';

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
      }
    }
  }
}
